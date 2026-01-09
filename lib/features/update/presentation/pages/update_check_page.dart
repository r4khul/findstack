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
      bottomNavigationBar: updateAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => _buildBottomActionBar(
          theme,
          label: "Try Again",
          icon: Icons.refresh_rounded,
          onPressed: _isManuallyChecking ? null : _handleCheckAgain,
          isLoading: _isManuallyChecking,
        ),
        data: (result) {
          if (result.errorType == UpdateErrorType.offline) {
            return _buildBottomActionBar(
              theme,
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
            return _buildBottomActionBar(
              theme,
              child: UpdateDownloadButton(
                url: result.config?.apkDirectDownloadUrl,
                version:
                    result.config?.latestNativeVersion.toString() ?? 'latest',
                isFullWidth: true,
              ),
            );
          } else {
            return _buildBottomActionBar(
              theme,
              label: _isManuallyChecking ? "Checking..." : "Check Again",
              icon: Icons.refresh_rounded,
              onPressed: _isManuallyChecking ? null : _handleCheckAgain,
              isLoading: _isManuallyChecking,
              isSecondary: true,
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomActionBar(
    ThemeData theme, {
    String? label,
    IconData? icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isSecondary = false,
    Widget? child,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child:
                  child ??
                  FilledButton.icon(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: isSecondary
                          ? theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5)
                          : theme.colorScheme.primary,
                      foregroundColor: isSecondary
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSecondary
                            ? BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.1,
                                ),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isSecondary
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(icon, size: 20),
                    label: Text(
                      label ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
            ),
          ),
        ),
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

            // Retry button removed (moved to bottom bar)

            // Padding for bottom bar
            const SizedBox(height: 80),
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
        if (!isUpdateAvailable) const Spacer(),
        // Hero Icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isUpdateAvailable
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUpdateAvailable
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isUpdateAvailable
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
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
            );
          },
        ),
        const SizedBox(height: 32),

        // Status & Version Info
        Text(
          isUpdateAvailable ? "Update Available" : "You're up to date",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          isUpdateAvailable
              ? "A new version of Unfilter is ready."
              : "Unfilter v$currentVersion is the latest version.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        // Version Comparison Grid
        if (isUpdateAvailable && result.config != null)
          _buildVersionComparisonCard(
            theme,
            currentVersion,
            result.config!.latestNativeVersion.toString(),
          ),

        if (isUpdateAvailable &&
            result.config != null &&
            (result.config!.hasChangelog ||
                result.config!.releaseNotes != null)) ...[
          const SizedBox(height: 24),
          _buildChangelogCard(theme, result.config!),
        ],

        if (!isUpdateAvailable) const Spacer(),

        // Bottom padding to avoid content being hidden behind navbar
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildVersionComparisonCard(
    ThemeData theme,
    String currentVersion,
    String newVersion,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildVersionColumn(
              theme,
              "Current",
              "v$currentVersion",
              false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _buildVersionColumn(theme, "Newest", "v$newVersion", true),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionColumn(
    ThemeData theme,
    String label,
    String version,
    bool isNew,
  ) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isNew
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        isNew
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  version,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                    letterSpacing: -0.5,
                  ),
                ),
              )
            : Text(
                version,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                ),
              ),
      ],
    );
  }

  Widget _buildChangelogCard(ThemeData theme, UpdateConfigModel config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's New",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See what has changed",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (config.releaseNotes != null) ...[
            Text(
              config.releaseNotes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (config.features.isNotEmpty) ...[
            _buildChangelogSectionHeader(
              theme,
              "FEATURES",
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            ...config.features.map(
              (f) => _buildChangelogItem(
                theme,
                f,
                Icons.star_rounded,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (config.fixes.isNotEmpty) ...[
            _buildChangelogSectionHeader(
              theme,
              "FIXES",
              const Color(0xFF2196F3),
            ),
            const SizedBox(height: 12),
            ...config.fixes.map(
              (f) => _buildChangelogItem(
                theme,
                f,
                Icons.bug_report_rounded,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangelogSectionHeader(
    ThemeData theme,
    String title,
    Color color,
  ) {
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        fontSize: 11,
        color: color,
      ),
    );
  }

  Widget _buildChangelogItem(
    ThemeData theme,
    String text,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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

            // Retry button removed (moved to bottom bar)
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
}
