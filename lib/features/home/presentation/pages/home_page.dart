import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/app_count_badge.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../search/presentation/providers/tech_stack_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/back_to_top_fab.dart';
import '../widgets/constants.dart';
import '../widgets/home_sliver_delegate.dart';
import '../widgets/permission_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions(fromResume: true);
      ref.read(installedAppsProvider.notifier).backgroundRevalidate();
    }
  }

  Future<void> _checkPermissions({bool fromResume = false}) async {
    if (!mounted) return;

    try {
      final repository = ref.read(deviceAppsRepositoryProvider);
      final hasPermission = await repository.checkUsagePermission();

      if (!mounted) return;

      if (hasPermission) {
        await _handlePermissionGranted(fromResume);
      } else {
        _handlePermissionDenied(fromResume, repository);
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _handlePermissionGranted(bool fromResume) async {
    if (_isDialogShowing) {
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }

    if (!fromResume && _isDialogShowing) return;

    try {
      if (ref.read(installedAppsProvider).isLoading) {
        await ref.read(installedAppsProvider.future);
      }
    } catch (_) {
    }

    if (!mounted) return;

    final appsState = ref.read(installedAppsProvider);
    final hasData = appsState.value?.isNotEmpty ?? false;

    if (!hasData) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ScanPage()));
      }
    }
  }

  void _handlePermissionDenied(bool fromResume, dynamic repository) {
    if (!fromResume && !_isDialogShowing) {
      _showPermissionDialog(repository);
    }
  }

  Future<void> _showPermissionDialog(dynamic repository) async {
    _isDialogShowing = true;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Permission',
      transitionDuration: HomeAnimationDurations.standard,
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ).value,
          child: Opacity(
            opacity: anim1.value,
            child: PermissionDialog(
              isPermanent: true,
              onGrantPressed: () async {
                await repository.requestUsagePermission();
              },
            ),
          ),
        );
      },
    );

    _isDialogShowing = false;
  }

  void _onScroll() {
    if (!mounted) return;

    final shouldShow =
        _scrollController.offset > HomeDimensions.backToTopThreshold;

    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const AppDrawer(),
      floatingActionButton: BackToTopFab(
        isVisible: _showBackToTop,
        onPressed: _scrollToTop,
      ),
      body: AnimatedSwitcher(
        duration: HomeAnimationDurations.standard,
        child: appsAsync.when(
          data: (apps) => _buildAppsList(apps, isLoading: apps.isEmpty),
          loading: () => _buildAppsList(_dummyApps, isLoading: true),
          error: (err, stack) => _buildErrorState(theme, err),
        ),
      ),
    );
  }

  Widget _buildAppsList(List<DeviceApp> apps, {required bool isLoading}) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    const minHeight = 170.0;
    const maxHeight = 260.0;

    final filteredApps = isLoading ? apps : _filterApps(apps);
    final isDark = theme.brightness == Brightness.dark;

    return AppCountOverlay(
      count: filteredApps.length,
      child: CustomScrollView(
        controller: _scrollController,
        key: const ValueKey('data'),
        physics: isLoading
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: HomeSliverDelegate(
              appCount: apps.length,
              expandedHeight: maxHeight + topPadding,
              collapsedHeight: minHeight + topPadding,
              isLoading: isLoading,
            ),
          ),
          if (!isLoading && filteredApps.isEmpty)
            _buildEmptyState(theme)
          else
            _buildAppsSliver(filteredApps, isLoading, isDark, theme),
        ],
      ),
    );
  }

  List<DeviceApp> _filterApps(List<DeviceApp> apps) {
    final category = ref.watch(categoryFilterProvider);
    final techStack = ref.watch(techStackFilterProvider);

    return apps.where((app) {
      final matchesCategory = category == null || app.category == category;

      bool matchesStack = true;
      if (techStack != null && techStack != 'All') {
        if (techStack == 'Android') {
          matchesStack = ['Java', 'Kotlin', 'Android'].contains(app.stack);
        } else {
          matchesStack = app.stack.toLowerCase() == techStack.toLowerCase();
        }
      }

      return matchesCategory && matchesStack;
    }).toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.app_blocking_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No apps found matching criteria',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsSliver(
    List<DeviceApp> apps,
    bool isLoading,
    bool isDark,
    ThemeData theme,
  ) {
    return Skeletonizer.sliver(
      enabled: isLoading,
      effect: ShimmerEffect(
        baseColor: isDark
            ? HomeShimmerColors.darkBase
            : HomeShimmerColors.lightBase,
        highlightColor: isDark
            ? HomeShimmerColors.darkHighlight
            : HomeShimmerColors.lightHighlight,
        duration: HomeAnimationDurations.shimmer,
      ),
      textBoneBorderRadius: TextBoneBorderRadius(BorderRadius.circular(4)),
      justifyMultiLineText: true,
      containersColor: theme.colorScheme.surface,
      child: SliverPadding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              key: ValueKey(apps[index].packageName),
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(app: apps[index]),
            ),
            childCount: apps.length,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'Something went wrong while scanning.\n$error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

final List<DeviceApp> _dummyApps = List.generate(
  10,
  (index) => DeviceApp(
    appName: 'Application Name',
    packageName: 'com.example.application.$index',
    stack: 'Flutter',
    nativeLibraries: const [],
    permissions: const [],
    services: const [],
    receivers: const [],
    providers: const [],
    installDate: DateTime.now(),
    updateDate: DateTime.now(),
    minSdkVersion: 21,
    targetSdkVersion: 33,
    uid: 1000,
    versionCode: 1,
    category: AppCategory.productivity,
  ),
);
