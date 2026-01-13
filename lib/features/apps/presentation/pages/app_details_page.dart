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

  late DeviceApp _currentApp;

  DeviceApp get app => _currentApp;

  @override
  void initState() {
    super.initState();
    _currentApp = widget.app;
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PremiumSliverAppBar(
            title: "App Details",
            onResync: _isResyncing ? null : _handleResync,
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

                  AppStatsRow(app: app),
                  const SizedBox(height: AppDetailsSpacing.section),

                  ActivitySection(app: app, historyAsync: usageHistoryAsync),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
