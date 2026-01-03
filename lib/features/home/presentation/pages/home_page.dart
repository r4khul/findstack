import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/app_count_badge.dart';
import '../../../search/presentation/providers/tech_stack_provider.dart';
import '../widgets/home_sliver_delegate.dart';
import '../widgets/back_to_top_fab.dart';
import '../widgets/app_drawer.dart';
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
      // Re-check permission when app resumes
      _checkPermissions(fromResume: true);
    }
  }

  Future<void> _checkPermissions({bool fromResume = false}) async {
    // If just checking externally (resume), we shouldn't be blocked by "checking" flag
    // But we still want to avoid double-invocation if not necessary.
    // Actually, calling checkUsagePermission() is fast/harmless.
    // The previous flag _isCheckingPermission was blocking the resume check because the dialog await kept it true.

    if (!mounted) return;

    try {
      final repository = ref.read(deviceAppsRepositoryProvider);
      final hasPermission = await repository.checkUsagePermission();

      if (!mounted) return;

      if (hasPermission) {
        // Permission Granted!
        if (_isDialogShowing) {
          Navigator.of(context).pop(); // Dismiss the dialog
          _isDialogShowing = false;
        }

        // If we just got permission (fromResume) OR if the list is empty/stale, trigger scan.
        // We can just trigger full scan to be safe, apps provider handles optimization?
        // Actually, let's only trigger if we think we haven't scanned yet.
        // But for safety:
        if (fromResume || !_isDialogShowing) {
          final appsState = ref.read(installedAppsProvider);
          final hasData = appsState.value?.isNotEmpty ?? false;

          if (!hasData) {
            ref.read(installedAppsProvider.notifier).fullScan();
          }
        }
      } else {
        // Permission Denied
        if (!fromResume && !_isDialogShowing) {
          // Only show dialog if this is the initial check and it's not already open
          await _showPermissionDialog(repository);
        } else if (fromResume && _isDialogShowing) {
          // User came back but still didn't grant permission.
          // Dialog is still showing. Do nothing, let them try again.
        }
      }
    } catch (e) {
      print("Error checking permissions: $e");
    }
  }

  Future<void> _showPermissionDialog(dynamic repository) async {
    _isDialogShowing = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Permission",
      transitionDuration: const Duration(milliseconds: 300),
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
                // We rely on didChangeAppLifecycleState to detect return
              },
            ),
          ),
        );
      },
    );
    // Dialog dismissed (either by code or user if we allowed it)
    _isDialogShowing = false;
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 300 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  static final List<DeviceApp> _dummyApps = List.generate(
    10,
    (index) => DeviceApp(
      appName: 'Application Name',
      packageName: 'com.example.application',
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

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final theme = Theme.of(context);

    // Calculate heights
    // Search(50) + V-Spacing(12) + Category(40) + V-Spacing(12) = 114
    // + Toolbar(56) = 170 + Top Padding
    final topPadding = MediaQuery.of(context).padding.top;
    final minHeight = 170.0 + topPadding;
    final maxHeight = 260.0 + topPadding;

    // Helper to build the content
    Widget buildContent(List<DeviceApp> apps, {bool isLoading = false}) {
      final category = ref.watch(categoryFilterProvider);
      final techStack = ref.watch(techStackFilterProvider);

      // If loading, we use the full list (dummy) as is.
      // If not loading, we filter.
      final filteredApps = isLoading
          ? apps
          : apps.where((app) {
              final matchesCategory =
                  category == null || app.category == category;
              bool matchesStack = true;
              if (techStack != null && techStack != 'All') {
                if (techStack == 'Android') {
                  matchesStack = [
                    'Java',
                    'Kotlin',
                    'Android',
                  ].contains(app.stack);
                } else {
                  matchesStack =
                      app.stack.toLowerCase() == techStack.toLowerCase();
                }
              }
              return matchesCategory && matchesStack;
            }).toList();

      final isDark = theme.brightness == Brightness.dark;

      return Skeletonizer(
        enabled: isLoading,
        // Use opaque colors for a cleaner, premium look
        effect: ShimmerEffect(
          baseColor: isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0),
          highlightColor: isDark
              ? const Color(0xFF424242)
              : const Color(0xFFFAFAFA),
          duration: const Duration(milliseconds: 1500),
        ),
        textBoneBorderRadius: TextBoneBorderRadius(BorderRadius.circular(4)),
        justifyMultiLineText: true,
        containersColor: theme.colorScheme.surface,
        child: AppCountOverlay(
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
                  expandedHeight: maxHeight,
                  collapsedHeight: minHeight,
                ),
              ),
              if (!isLoading && filteredApps.isEmpty)
                SliverFillRemaining(
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
                          "No apps found matching criteria",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    20 + MediaQuery.of(context).padding.bottom,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(app: filteredApps[index]),
                      ),
                      childCount: filteredApps.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const AppDrawer(),
      floatingActionButton: BackToTopFab(
        isVisible: _showBackToTop,
        onPressed: _scrollToTop,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: appsAsync.when(
          data: (apps) {
            // If apps is empty, we treat it as loading (initial scan state)
            // This prevents "0 apps" flash.
            if (apps.isEmpty) {
              return buildContent(_dummyApps, isLoading: true);
            }
            return buildContent(apps, isLoading: false);
          },
          loading: () => buildContent(_dummyApps, isLoading: true),
          error: (err, stack) => Center(
            key: const ValueKey('error'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Something went wrong while scanning.\n$err",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
