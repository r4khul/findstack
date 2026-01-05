import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/update_service.dart';
import '../providers/update_provider.dart';
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
                ? Colors.blueAccent.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUpdateAvailable
                ? Icons.rocket_launch_rounded
                : Icons.check_circle_rounded,
            size: 80,
            color: isUpdateAvailable
                ? Colors.blueAccent
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),

        // Status Text
        Text(
          isUpdateAvailable ? "Update Available" : "You're up to date",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
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
          ),
          textAlign: TextAlign.center,
        ),

        if (isUpdateAvailable && result.config != null) ...[
          const Spacer(),
          // Version Diff Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
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
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.config!.releaseNotes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
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
              ? DownloadButton(
                  url: result.config?.apkDirectDownloadUrl,
                  theme: theme,
                )
              : OutlinedButton(
                  onPressed: () {
                    ref.invalidate(updateCheckProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Check Again"),
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

// Separate widget to consume DownloadController cleanly
class DownloadButton extends ConsumerWidget {
  final String? url;
  final ThemeData theme;

  const DownloadButton({super.key, required this.url, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);
    final notifier = ref.read(updateDownloadProvider.notifier);

    if (downloadState.isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: downloadState.progress,
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Downloading... ${(downloadState.progress * 100).toInt()}%",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (downloadState.isDone) {
      return ElevatedButton(
        onPressed: () async {
          if (downloadState.filePath != null) {
            final file = File(downloadState.filePath!);
            await ref.read(updateServiceFutureProvider).value?.installApk(file);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text("Install Update"),
      );
    }

    if (downloadState.error != null) {
      return Column(
        children: [
          Text(
            "Download failed. Please try again.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => notifier.reset(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: () {
        if (url != null) {
          notifier.downloadAndInstall(url!);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
      ),
      child: const Text("Download & Install"),
    );
  }
}
