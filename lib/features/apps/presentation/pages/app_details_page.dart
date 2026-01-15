library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../domain/entities/device_app.dart';
import '../providers/app_detail_provider.dart';
import '../providers/apps_provider.dart';
import '../widgets/app_details/app_details_widgets.dart';
import '../widgets/app_details/snackbar_utils.dart';
import '../widgets/share_preview_dialog.dart';

class AppDetailsPage extends ConsumerStatefulWidget {
  final DeviceApp app;

  const AppDetailsPage({super.key, required this.app});

  @override
  ConsumerState<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends ConsumerState<AppDetailsPage> {
  bool _isResyncing = false;
  bool _isInitialLoading = false;

  late DeviceApp _currentApp;

  DeviceApp get app => _currentApp;

  /// Detects if the app data is minimal/incomplete (e.g., from Task Manager)
  bool get _isIncompleteData =>
      _currentApp.stack == 'Loading...' ||
      (_currentApp.minSdkVersion == 0 && _currentApp.targetSdkVersion == 0);

  @override
  void initState() {
    super.initState();
    _currentApp = widget.app;

    // Auto-fetch full details if we received incomplete data
    if (_isIncompleteData) {
      _autoFetchDetails();
    }
  }

  Future<void> _autoFetchDetails() async {
    setState(() => _isInitialLoading = true);

    try {
      final updatedApp = await ref
          .read(installedAppsProvider.notifier)
          .resyncApp(_currentApp.packageName);

      if (updatedApp != null && mounted) {
        setState(() {
          _currentApp = updatedApp;
          _isInitialLoading = false;
        });
      } else if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    } catch (e) {
      debugPrint('Auto-fetch error: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _handleResync() async {
    if (_isResyncing) return;

    setState(() => _isResyncing = true);

    try {
      ref.invalidate(
        appUsageHistoryProvider((
          packageName: _currentApp.packageName,
          installTime: _currentApp.installDate.millisecondsSinceEpoch,
        )),
      );

      final updatedApp = await ref
          .read(installedAppsProvider.notifier)
          .resyncApp(_currentApp.packageName);

      if (updatedApp != null && mounted) {
        setState(() {
          _currentApp = updatedApp;
        });

        _showSnackbar(
          icon: Icons.check_circle_rounded,
          message: 'App data refreshed',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('Resync error: $e');
      if (mounted) {
        _showSnackbar(
          icon: Icons.error_outline_rounded,
          message: 'Failed to resync',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isResyncing = false);
    }
  }

  void _showSnackbar({
    required IconData icon,
    required String message,
    required bool isSuccess,
  }) {
    showPremiumSnackbar(
      context: context,
      icon: icon,
      message: message,
      isSuccess: isSuccess,
    );
  }

  void _openShareDialog() {
    SharePreviewDialog.show(context, app);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageHistoryAsync = ref.watch(
      appUsageHistoryProvider((
        packageName: app.packageName,
        installTime: app.installDate.millisecondsSinceEpoch,
      )),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              PremiumSliverAppBar(
                title: "App Details",
                onResync: (_isResyncing || _isInitialLoading)
                    ? null
                    : _handleResync,
                onShare: _openShareDialog,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDetailsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeaderCard(app: app, onShare: _openShareDialog),
                      const SizedBox(height: AppDetailsSpacing.section),

                      if (!_isInitialLoading) ...[
                        AppStatsRow(app: app),
                        const SizedBox(height: AppDetailsSpacing.section),

                        ActivitySection(
                          app: app,
                          historyAsync: usageHistoryAsync,
                        ),
                        const SizedBox(height: AppDetailsSpacing.section),

                        AppInfoSection(app: app),
                        const SizedBox(height: AppDetailsSpacing.section),

                        DeepInsightsSection(app: app),
                        const SizedBox(height: AppDetailsSpacing.section),

                        if (app.nativeLibraries.isNotEmpty) ...[
                          NativeLibsSection(app: app),
                          const SizedBox(height: AppDetailsSpacing.section),
                        ],

                        DeveloperSection(app: app),
                        const SizedBox(height: AppDetailsSpacing.section),

                        if (app.permissions.isNotEmpty) ...[
                          PermissionsSection(app: app),
                          const SizedBox(height: AppDetailsSpacing.bottom),
                        ],
                      ] else ...[
                        _buildLoadingPlaceholder(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isInitialLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(top: 100),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.95,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Loading app details...",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
