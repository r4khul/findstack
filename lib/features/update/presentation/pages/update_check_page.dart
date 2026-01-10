/// The main update check page for the application.
///
/// This page allows users to manually check for app updates,
/// view version information, and download new versions.
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

/// The update check page that shows current version status.
///
/// This page displays:
/// - Loading state while checking for updates
/// - Error state if check fails
/// - "Up to date" state if no updates available
/// - "Update available" state with version info and download button
///
/// ## Features
/// - Automatic update check on page load
/// - Manual "Check Again" functionality with connectivity awareness
/// - Premium connectivity dialogs for offline/server issues
/// - Floating bottom action bar for actions
///
/// ## Usage
/// Navigate to this page when user wants to check for updates:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const UpdateCheckPage()),
/// );
/// ```
class UpdateCheckPage extends ConsumerStatefulWidget {
  /// Creates an update check page.
  const UpdateCheckPage({super.key});

  @override
  ConsumerState<UpdateCheckPage> createState() => _UpdateCheckPageState();
}

class _UpdateCheckPageState extends ConsumerState<UpdateCheckPage>
    with SingleTickerProviderStateMixin {
  /// Whether a manual check is currently in progress.
  bool _isManuallyChecking = false;

  /// Animation controller for pulse effects in loading states.
  late AnimationController _pulseController;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _triggerInitialCheck();
  }

  /// Initializes the pulse animation controller.
  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: UpdateAnimationDurations.pulse,
    )..repeat(reverse: true);
  }

  /// Triggers a fresh update check when entering the page.
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

  // ===========================================================================
  // EVENT HANDLERS
  // ===========================================================================

  /// Handles the "Check Again" button press with connectivity awareness.
  ///
  /// This method:
  /// 1. Prevents double-tap by checking [_isManuallyChecking]
  /// 2. Checks connectivity before making network request
  /// 3. Shows appropriate dialog if offline or server unreachable
  /// 4. Triggers a fresh update check if connectivity is OK
  Future<void> _handleCheckAgain() async {
    if (_isManuallyChecking) return;

    setState(() => _isManuallyChecking = true);
    HapticFeedback.mediumImpact();

    // First check connectivity
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

    // Connectivity OK, proceed with update check
    ref.invalidate(updateCheckProvider);

    // Wait a bit for the provider to start loading, then reset the flag
    await Future.delayed(UpdateAnimationDurations.checkAgainDelay);
    if (mounted) {
      setState(() => _isManuallyChecking = false);
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

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

  /// Builds the appropriate content based on update check result.
  Widget _buildResultContent(UpdateCheckResult result) {
    // Handle connectivity errors in result
    if (result.errorType == UpdateErrorType.offline) {
      return UpdateCheckOfflineState(pulseController: _pulseController);
    }

    return UpdateCheckResultState(result: result);
  }

  /// Builds the bottom action bar based on current state.
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

  /// Builds the bottom bar for a successful update check result.
  Widget _buildResultBottomBar(UpdateCheckResult result) {
    // Show retry for offline state
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

    // Show download button if update is available
    if (isUpdateAvailable) {
      return UpdateBottomActionBar(
        child: UpdateDownloadButton(
          url: result.config?.apkDirectDownloadUrl,
          version: result.config?.latestNativeVersion.toString() ?? 'latest',
          isFullWidth: true,
        ),
      );
    }

    // Show check again button if up to date
    return UpdateBottomActionBar(
      label: _isManuallyChecking ? "Checking..." : "Check Again",
      icon: Icons.refresh_rounded,
      onPressed: _isManuallyChecking ? null : _handleCheckAgain,
      isLoading: _isManuallyChecking,
      isSecondary: true,
    );
  }
}
