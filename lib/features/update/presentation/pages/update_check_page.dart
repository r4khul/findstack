import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/update_service.dart';
import '../providers/update_provider.dart';
import '../widgets/update_ui.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';

class UpdateCheckPage extends ConsumerStatefulWidget {
  const UpdateCheckPage({super.key});

  @override
  ConsumerState<UpdateCheckPage> createState() => _UpdateCheckPageState();
}

class _UpdateCheckPageState extends ConsumerState<UpdateCheckPage> {
  @override
  void initState() {
    super.initState();
    // Trigger a fresh check when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(updateCheckProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final updateAsync = ref.watch(updateCheckProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No standard AppBar, we use CustomScrollView with PremiumSliverAppBar
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
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Checking for updates...",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Error",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Unable to check for updates. Please check your internet connection and try again.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.invalidate(updateCheckProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState(
    BuildContext context,
    UpdateCheckResult result,
    ThemeData theme,
    bool isDark,
  ) {
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
          // Version Diff Card
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
                      ishighlighted: true,
                    ),
                  ],
                ),
                if (result.config!.releaseNotes != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Divider(height: 1),
                  ),
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
              : OutlinedButton(
                  onPressed: () {
                    ref.invalidate(updateCheckProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  child: const Text(
                    "Check Again",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVersionColumn(
    ThemeData theme,
    String label,
    String version, {
    bool ishighlighted = false,
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
            color: ishighlighted
                ? Colors.blueAccent
                : theme.colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
