library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_service.dart';
import '../providers/update_provider.dart';
import '../widgets/constants.dart';
import '../widgets/connectivity_dialog.dart';
import '../widgets/update_check_states.dart';
import '../widgets/update_bottom_action_bar.dart';
import '../widgets/update_download_button.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../../../core/services/connectivity_service.dart';

class UpdateCheckPage extends ConsumerStatefulWidget {
  const UpdateCheckPage({super.key});

  @override
  ConsumerState<UpdateCheckPage> createState() => _UpdateCheckPageState();
}

class _UpdateCheckPageState extends ConsumerState<UpdateCheckPage>
    with SingleTickerProviderStateMixin {
  bool _isManuallyChecking = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _triggerInitialCheck();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: UpdateAnimationDurations.pulse,
    )..repeat(reverse: true);
  }

  void _triggerInitialCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(updateCheckProvider);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckAgain() async {
    if (_isManuallyChecking) return;

    setState(() => _isManuallyChecking = true);
    HapticFeedback.mediumImpact();

    final connectivity = ref.read(connectivityServiceProvider);
    final status = await connectivity.checkConnectivity();

    if (status == ConnectivityStatus.offline) {
      if (mounted) {
        showConnectivityDialog(
          context: context,
          title: 'No Internet Connection',
          message:
              'Please connect to WiFi or mobile data to check for updates.',
          icon: Icons.wifi_off_rounded,
          status: status,
          onRetry: _handleCheckAgain,
        );
        setState(() => _isManuallyChecking = false);
      }
      return;
    }

    if (status == ConnectivityStatus.serverUnreachable) {
      if (mounted) {
        showConnectivityDialog(
          context: context,
          title: 'Server Unavailable',
          message:
              'The update server is temporarily unreachable. Please try again later.',
          icon: Icons.cloud_off_rounded,
          status: status,
          onRetry: _handleCheckAgain,
        );
        setState(() => _isManuallyChecking = false);
      }
      return;
    }

    ref.invalidate(updateCheckProvider);

    await Future.delayed(UpdateAnimationDurations.checkAgainDelay);
    if (mounted) {
      setState(() => _isManuallyChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateAsync = ref.watch(updateCheckProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(title: "System Update"),
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UpdateSpacing.xl,
                ),
                child: updateAsync.when(
                  loading: () => UpdateCheckLoadingState(
                    pulseController: _pulseController,
                  ),
                  error: (e, stack) =>
                      UpdateCheckErrorState(error: e.toString()),
                  data: (result) => _buildResultContent(result),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(updateAsync),
    );
  }

  Widget _buildResultContent(UpdateCheckResult result) {
    if (result.errorType == UpdateErrorType.offline) {
      return UpdateCheckOfflineState(pulseController: _pulseController);
    }

    return UpdateCheckResultState(result: result);
  }

  Widget _buildBottomBar(AsyncValue<UpdateCheckResult> updateAsync) {
    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => UpdateBottomActionBar(
        label: "Try Again",
        icon: Icons.refresh_rounded,
        onPressed: _isManuallyChecking ? null : _handleCheckAgain,
        isLoading: _isManuallyChecking,
      ),
      data: (result) => _buildResultBottomBar(result),
    );
  }

  Widget _buildResultBottomBar(UpdateCheckResult result) {
    if (result.errorType == UpdateErrorType.offline) {
      return UpdateBottomActionBar(
        label: "Try Again",
        icon: Icons.refresh_rounded,
        onPressed: _isManuallyChecking ? null : _handleCheckAgain,
        isLoading: _isManuallyChecking,
      );
    }

    final isUpdateAvailable =
        result.status == UpdateStatus.softUpdate ||
        result.status == UpdateStatus.forceUpdate;

    if (isUpdateAvailable) {
      return UpdateBottomActionBar(
        child: UpdateDownloadButton(
          url: result.config?.apkDirectDownloadUrl,
          version: result.config?.latestNativeVersion.toString() ?? 'latest',
          isFullWidth: true,
        ),
      );
    }

    return UpdateBottomActionBar(
      label: _isManuallyChecking ? "Checking..." : "Check Again",
      icon: Icons.refresh_rounded,
      onPressed: _isManuallyChecking ? null : _handleCheckAgain,
      isLoading: _isManuallyChecking,
      isSecondary: true,
    );
  }
}
