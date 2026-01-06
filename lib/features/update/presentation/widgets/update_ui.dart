import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_service.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/update_provider.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/navigation/active_route_provider.dart';

class VersionCheckGate extends ConsumerWidget {
  final Widget child;

  const VersionCheckGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check onboarding status first
    final onboardingState = ref.watch(onboardingStateProvider);
    // If onboarding is loading or not completed, suppress updates
    if (onboardingState.asData?.value != true) {
      return Stack(children: [child]);
    }

    // Watch the update check result
    final updateResultAsync = ref.watch(updateCheckProvider);
    final activeRoute = ref.watch(activeRouteProvider);

    return updateResultAsync.when(
      data: (result) {
        if (result.status == UpdateStatus.forceUpdate) {
          return ForceUpdateScreen(result: result);
        }

        // Check if we should suppress the banner on specific pages
        final shouldShowBanner =
            result.status == UpdateStatus.softUpdate &&
            activeRoute != AppRoutes.scan;

        // Ensure child is built even if soft update is available
        // We will overlay the banner using a Stack
        return Stack(
          children: [
            child,
            if (shouldShowBanner)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SoftUpdateBanner(result: result),
              ),
          ],
        );
      },
      loading: () =>
          Stack(children: [child]), // Passively show app while loading
      error: (e, stack) {
        // Log error but don't block app
        debugPrint('Update check error: $e');
        return Stack(children: [child]);
      },
    );
  }
}

class ForceUpdateScreen extends ConsumerWidget {
  final UpdateCheckResult result;

  const ForceUpdateScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Lock Android back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background ambient glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox(),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    // Premium Icon Container
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.system_security_update_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Title
                    Text(
                      'Critical Update Required',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      'A critical update is available that improves stability and security.\nYou must update to continue using UnFilter.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Version info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _VersionCol(
                              label: 'Current',
                              version: result.currentVersion?.toString() ?? '?',
                              isOld: true,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          Expanded(
                            child: _VersionCol(
                              label: 'Required',
                              version:
                                  result.config?.latestNativeVersion
                                      .toString() ??
                                  'Latest',
                              isHighlight: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Release Notes (Mini)
                    if (result.config?.releaseNotes != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                result.config!.releaseNotes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    UpdateDownloadButton(
                      url: result.config?.apkDirectDownloadUrl,
                      version:
                          result.config?.latestNativeVersion.toString() ??
                          'latest',
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCol extends StatelessWidget {
  final String label;
  final String version;
  final bool isHighlight;
  final bool isOld;

  const _VersionCol({
    required this.label,
    required this.version,
    this.isHighlight = false,
    this.isOld = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
            fontFamily: 'monospace',
            color: isHighlight
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class SoftUpdateBanner extends ConsumerStatefulWidget {
  final UpdateCheckResult result;

  const SoftUpdateBanner({super.key, required this.result});

  @override
  ConsumerState<SoftUpdateBanner> createState() => _SoftUpdateBannerState();
}

class _SoftUpdateBannerState extends ConsumerState<SoftUpdateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Delayed start to not interact with initial app load
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      // Don't actually remove from tree to keep state simpler, just hide
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // isDark variable unused, removing it.

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        // Glassmorphism effect
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Available',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${widget.result.config?.latestNativeVersion} is ready',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.all(8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  UpdateDownloadButton(
                    url: widget.result.config?.apkDirectDownloadUrl,
                    version:
                        widget.result.config?.latestNativeVersion.toString() ??
                        'latest',
                    isCompact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateDownloadButton extends ConsumerWidget {
  final String? url;
  final String version;
  final bool isCompact;
  final bool isFullWidth;

  const UpdateDownloadButton({
    super.key,
    this.url,
    required this.version,
    this.isCompact = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);
    final notifier = ref.read(updateDownloadProvider.notifier);
    final theme = Theme.of(context);

    Widget content;

    if (downloadState.isDownloading) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              value: downloadState.progress,
              strokeWidth: 2.5,
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(downloadState.progress * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
              fontFamily: 'UncutSans',
            ),
          ),
        ],
      );
    } else if (downloadState.isDone) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.system_update,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            'Install Update',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      );
    } else if (downloadState.error != null) {
      content = Text(
        'Retry Download',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onError,
        ),
      );
    } else {
      content = Text(
        'Update Now',
        style: TextStyle(
          fontSize: isCompact ? 14 : 16,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      );
    }

    // Button Colors
    Color? bgColor;
    Color? fgColor;

    if (downloadState.isDone) {
      // "Premium Green" requested for install
      // Using a more sophisticated, "Minimal UI" green for better theme harmony
      bgColor = const Color(0xFF00BB2D);
      fgColor = Colors.white;
    } else if (downloadState.error != null) {
      bgColor = theme.colorScheme.error;
      fgColor = theme.colorScheme.onError;
    } else {
      // Default: Primary Color (Monochrome)
      bgColor = theme.colorScheme.primary;
      fgColor = theme.colorScheme.onPrimary;
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: isCompact ? 48 : 56,
      child: ElevatedButton(
        onPressed: () {
          if (downloadState.isDownloading) return;

          if (downloadState.isDone && downloadState.filePath != null) {
            final file = File(downloadState.filePath!);
            ref.read(updateServiceFutureProvider).value?.installApk(file);
          } else if (downloadState.error != null) {
            notifier.reset();
            if (url != null) {
              notifier.downloadAndInstall(url!, version);
            }
          } else {
            if (url != null) {
              notifier.downloadAndInstall(url!, version);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'UncutSans',
            letterSpacing: -0.5,
          ),
        ),
        child: content,
      ),
    );
  }
}
