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

/// Home page of the application.
///
/// Displays the list of installed apps with a collapsible header containing
/// search, category filters, and app statistics. Handles usage permission
/// requests and app lifecycle events for background revalidation.
///
/// ## Features
/// - Collapsible header with stats, search, and filters
/// - Back-to-top floating action button (appears after scrolling)
/// - Skeleton loading state during initial scan
/// - Empty state when no apps match filters
/// - Automatic permission handling
class HomePage extends ConsumerStatefulWidget {
  /// Creates the home page.
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
      // Trigger background revalidation with built-in throttling
      ref.read(installedAppsProvider.notifier).backgroundRevalidate();
    }
  }

  // ---------------------------------------------------------------------------
  // Permission Handling
  // ---------------------------------------------------------------------------

  /// Checks usage permission and handles navigation based on permission state.
  ///
  /// When [fromResume] is true, this is called from app lifecycle resume event.
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

  /// Handles the case when permission is already granted.
  Future<void> _handlePermissionGranted(bool fromResume) async {
    // Dismiss permission dialog if showing
    if (_isDialogShowing) {
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }

    if (!fromResume && _isDialogShowing) return;

    // Wait for provider initialization if loading
    try {
      if (ref.read(installedAppsProvider).isLoading) {
        await ref.read(installedAppsProvider.future);
      }
    } catch (_) {
      // Ignore errors - provider state will reflect error
    }

    if (!mounted) return;

    // Navigate to scan if no data available
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

  /// Handles the case when permission is denied.
  void _handlePermissionDenied(bool fromResume, dynamic repository) {
    if (!fromResume && !_isDialogShowing) {
      _showPermissionDialog(repository);
    }
    // If fromResume and dialog is showing, let user interact with it
  }

  /// Shows the permission request dialog.
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

  // ---------------------------------------------------------------------------
  // Scroll Handling
  // ---------------------------------------------------------------------------

  /// Handles scroll events to toggle the back-to-top FAB visibility.
  void _onScroll() {
    if (!mounted) return;

    final shouldShow =
        _scrollController.offset > HomeDimensions.backToTopThreshold;

    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  /// Animates scroll to top of the list.
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

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

  /// Builds the main apps list with header.
  Widget _buildAppsList(List<DeviceApp> apps, {required bool isLoading}) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    // Header height calculations
    const minHeight = 170.0;
    const maxHeight = 260.0;

    // Apply filters
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

  /// Filters apps based on current category and tech stack selections.
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

  /// Builds the empty state shown when no apps match filters.
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

  /// Builds the apps sliver list with skeleton loading.
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

  /// Builds the error state widget.
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

// -----------------------------------------------------------------------------
// Private Constants
// -----------------------------------------------------------------------------

/// Dummy apps for skeleton loading state.
///
/// Used to display placeholder cards while the actual app data is loading.
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
