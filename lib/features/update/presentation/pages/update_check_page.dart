import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/update_config_model.dart';
import '../../domain/update_service.dart';
import '../providers/update_provider.dart';
import '../widgets/update_ui.dart';
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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Trigger a fresh check when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(updateCheckProvider);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Handles the "Check Again" button press with connectivity awareness
  Future<void> _handleCheckAgain() async {
    if (_isManuallyChecking) return;

    setState(() => _isManuallyChecking = true);
    HapticFeedback.mediumImpact();

    // First check connectivity
    final connectivity = ref.read(connectivityServiceProvider);
    final status = await connectivity.checkConnectivity();

    if (status == ConnectivityStatus.offline) {
      if (mounted) {
        _showConnectivityDialog(
          title: 'No Internet Connection',
          message:
              'Please connect to WiFi or mobile data to check for updates.',
          icon: Icons.wifi_off_rounded,
          status: status,
        );
        setState(() => _isManuallyChecking = false);
      }
      return;
    }

    if (status == ConnectivityStatus.serverUnreachable) {
      if (mounted) {
        _showConnectivityDialog(
          title: 'Server Unavailable',
          message:
              'The update server is temporarily unreachable. Please try again later.',
          icon: Icons.cloud_off_rounded,
          status: status,
        );
        setState(() => _isManuallyChecking = false);
      }
      return;
    }

    // Connectivity OK, proceed with update check
    ref.invalidate(updateCheckProvider);

    // Wait a bit for the provider to start loading, then reset the flag
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isManuallyChecking = false);
    }
  }

  /// Shows a premium connectivity warning dialog
  void _showConnectivityDialog({
    required String title,
    required String message,
    required IconData icon,
    required ConnectivityStatus status,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with animated glow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: theme.colorScheme.error.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Connectivity tips
                    _buildConnectivityTips(theme, status),

                    const SizedBox(height: 28),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Dismiss',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _handleCheckAgain();
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectivityTips(ThemeData theme, ConnectivityStatus status) {
    final tips = status == ConnectivityStatus.offline
        ? [
            'Check if WiFi is enabled',
            'Check mobile data settings',
            'Try toggling airplane mode',
          ]
        : [
            'The update server may be undergoing maintenance',
            'Try again in a few minutes',
          ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Tips',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final updateAsync = ref.watch(updateCheckProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(title: "System Update"),
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: updateAsync.when(
                  loading: () => _buildLoadingState(theme),
                  error: (e, stack) => _buildErrorState(theme, e.toString()),
                  data: (result) =>
                      _buildResultState(context, result, theme, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated checking indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(
                    0.05 + (_pulseController.value * 0.05),
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            "Checking for updates...",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This may take a moment",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    // Determine error type and show appropriate UI
    final isNetworkError =
        error.toLowerCase().contains('internet') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('socket') ||
        error.toLowerCase().contains('network');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with subtle background
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              isNetworkError ? "No Connection" : "Something Went Wrong",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              isNetworkError
                  ? "Unable to check for updates. Please connect to the internet and try again."
                  : "We couldn't check for updates right now. Please try again later.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            if (isNetworkError) ...[
              const SizedBox(height: 24),
              _buildQuickNetworkTips(theme),
            ],

            const SizedBox(height: 40),

            // Retry button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isManuallyChecking ? null : _handleCheckAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isManuallyChecking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  _isManuallyChecking ? "Checking..." : "Try Again",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNetworkTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildTipRow(theme, Icons.wifi_rounded, 'Check WiFi connection'),
          const SizedBox(height: 8),
          _buildTipRow(
            theme,
            Icons.signal_cellular_alt_rounded,
            'Check mobile data',
          ),
          const SizedBox(height: 8),
          _buildTipRow(
            theme,
            Icons.airplanemode_active_rounded,
            'Toggle airplane mode',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResultState(
    BuildContext context,
    UpdateCheckResult result,
    ThemeData theme,
    bool isDark,
  ) {
    // Handle connectivity errors in result
    if (result.errorType == UpdateErrorType.offline) {
      return _buildOfflineState(theme);
    }

    final isUpdateAvailable =
        result.status == UpdateStatus.softUpdate ||
        result.status == UpdateStatus.forceUpdate;
    final currentVersion = result.currentVersion?.toString() ?? "Unknown";

    return Column(
      children: [
        const Spacer(flex: 2),

        // Hero Icon
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isUpdateAvailable
                ? theme.colorScheme.primary.withOpacity(0.05)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUpdateAvailable
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: isUpdateAvailable
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            isUpdateAvailable
                ? Icons.rocket_launch_rounded
                : Icons.check_circle_rounded,
            size: 64,
            color: isUpdateAvailable
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),

        // Status Text
        Text(
          isUpdateAvailable ? "Update Available" : "You're up to date",
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          isUpdateAvailable
              ? "A new version of Unfilter is ready to install."
              : "Unfilter v$currentVersion is the latest version available.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (isUpdateAvailable && result.config != null) ...[
          const Spacer(),
          // Version Diff Card with Changelog
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Version comparison row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildVersionColumn(theme, "Current", "v$currentVersion"),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.4,
                      ),
                    ),
                    _buildVersionColumn(
                      theme,
                      "Newest",
                      "v${result.config!.latestNativeVersion}",
                      isHighlighted: true,
                    ),
                  ],
                ),

                // Changelog preview section
                if (result.config!.hasChangelog ||
                    result.config!.releaseNotes != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Divider(height: 1),
                  ),

                  // Quick changelog summary
                  if (result.config!.hasChangelog) ...[
                    _buildChangelogPreview(theme, result.config!),
                    const SizedBox(height: 16),

                    // View Details button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _showChangelogBottomSheet(
                          context,
                          result.config!,
                          theme,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.08),
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "View Full Changelog",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (result.config!.releaseNotes != null) ...[
                    // Fallback to simple release notes if no detailed changelog
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "What's New",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.config!.releaseNotes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],

        const Spacer(flex: 3),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: isUpdateAvailable
              ? UpdateDownloadButton(
                  url: result.config?.apkDirectDownloadUrl,
                  version:
                      result.config?.latestNativeVersion.toString() ?? 'latest',
                  isFullWidth: true,
                )
              : FilledButton.icon(
                  onPressed: _isManuallyChecking ? null : _handleCheckAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  icon: _isManuallyChecking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    _isManuallyChecking ? "Checking..." : "Check Again",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Special state for when connectivity check returns offline
  Widget _buildOfflineState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated WiFi off icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(
                      0.08 + (_pulseController.value * 0.04),
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 56,
                    color: Colors.orange.withOpacity(0.9),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            Text(
              "You're Offline",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              "Connect to the internet to check for updates and download new versions.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Network tips card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildNetworkTipItem(
                    theme,
                    Icons.wifi_rounded,
                    "WiFi",
                    "Connect to a wireless network",
                  ),
                  Divider(
                    height: 24,
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  _buildNetworkTipItem(
                    theme,
                    Icons.signal_cellular_alt_rounded,
                    "Mobile Data",
                    "Enable cellular data in settings",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Retry button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isManuallyChecking ? null : _handleCheckAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isManuallyChecking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  _isManuallyChecking ? "Checking..." : "Try Again",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkTipItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionColumn(
    ThemeData theme,
    String label,
    String version, {
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          version,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? Colors.blueAccent
                : theme.colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Builds a compact preview of the changelog showing feature/fix counts
  Widget _buildChangelogPreview(ThemeData theme, UpdateConfigModel config) {
    return Row(
      children: [
        // Features count
        if (config.features.isNotEmpty) ...[
          _buildChangelogCountChip(
            theme,
            icon: Icons.auto_awesome_rounded,
            count: config.features.length,
            label: config.features.length == 1 ? 'Feature' : 'Features',
            color: const Color(0xFF4CAF50), // Premium green
          ),
          const SizedBox(width: 12),
        ],
        // Fixes count
        if (config.fixes.isNotEmpty)
          _buildChangelogCountChip(
            theme,
            icon: Icons.build_circle_rounded,
            count: config.fixes.length,
            label: config.fixes.length == 1 ? 'Fix' : 'Fixes',
            color: const Color(0xFF2196F3), // Premium blue
          ),
      ],
    );
  }

  Widget _buildChangelogCountChip(
    ThemeData theme, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a beautiful bottom sheet with the full changelog
  void _showChangelogBottomSheet(
    BuildContext context,
    UpdateConfigModel config,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "What's New",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Version ${config.latestNativeVersion}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Release notes (if any)
                        if (config.releaseNotes != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    config.releaseNotes!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Features section
                        if (config.features.isNotEmpty) ...[
                          _buildChangelogSection(
                            theme: theme,
                            title: 'New Features',
                            icon: Icons.auto_awesome_rounded,
                            color: const Color(0xFF4CAF50),
                            items: config.features,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Fixes section
                        if (config.fixes.isNotEmpty)
                          _buildChangelogSection(
                            theme: theme,
                            title: 'Bug Fixes',
                            icon: Icons.build_circle_rounded,
                            color: const Color(0xFF2196F3),
                            items: config.fixes,
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChangelogSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${items.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Items list
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
