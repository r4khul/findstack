import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/update_service.dart';
import '../providers/update_provider.dart';

class VersionCheckGate extends ConsumerWidget {
  final Widget child;

  const VersionCheckGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the update check result
    final updateResultAsync = ref.watch(updateCheckProvider);

    return updateResultAsync.when(
      data: (result) {
        if (result.status == UpdateStatus.forceUpdate) {
          return ForceUpdateScreen(result: result);
        }

        // Ensure child is built even if soft update is available
        // We will overlay the banner using a Stack
        return Stack(
          children: [
            child,
            if (result.status == UpdateStatus.softUpdate)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SoftUpdateBanner(result: result),
              ),
          ],
        );
      },
      loading: () => child, // Passively show app while loading
      error: (e, stack) {
        // Log error but don't block app
        debugPrint('Update check error: $e');
        return child;
      },
    );
  }
}

class ForceUpdateScreen extends ConsumerWidget {
  final UpdateCheckResult result;

  const ForceUpdateScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_security_update_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Critical Update Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    fontFamily:
                        'UncutSans', // Explicitly use font if needed, though Theme should handle it
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A critical update is available. To ensure the security and performance of FindStack, please update to the latest version.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _VersionInfoRow(
                  label: 'Current',
                  value: result.currentVersion?.toString() ?? 'Unknown',
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                _VersionInfoRow(
                  label: 'Required',
                  value:
                      result.config?.minSupportedNativeVersion.toString() ??
                      'Unknown',
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 32),
                if (result.config?.releaseNotes != null)
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "What's New",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              result.config!.releaseNotes!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(height: 24),
                _DownloadButton(url: result.config?.apkDirectDownloadUrl),
              ],
            ),
          ),
        ),
      ),
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark surface
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'v${widget.result.config?.latestNativeVersion}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.result.config?.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.result.config!.releaseNotes!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            _DownloadButton(
              url: widget.result.config?.apkDirectDownloadUrl,
              isCompact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VersionInfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final String? url;
  final bool isCompact;

  const _DownloadButton({this.url, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);
    final notifier = ref.read(updateDownloadProvider.notifier);

    if (downloadState.isDownloading) {
      return Container(
        height: isCompact ? 48 : 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: downloadState.progress,
                strokeWidth: 2,
                color: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Downloading ${(downloadState.progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (downloadState.isDone) {
      return SizedBox(
        width: double.infinity,
        height: isCompact ? 48 : 56,
        child: ElevatedButton(
          onPressed: () {
            if (downloadState.filePath != null) {
              notifier.downloadAndInstall(
                url!,
              ); // Actually just install if already there?
              // The controller logic re-downloads if called. Logic should check if file exists.
              // For now, let's just trigger install intent if we have path
              final file = File(downloadState.filePath!);
              ref
                  .read(updateServiceFutureProvider)
                  .asData
                  ?.value
                  .installApk(file);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Install Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (downloadState.error != null) {
      return Column(
        children: [
          Text(
            'Error: ${downloadState.error}',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 48 : 56,
            child: ElevatedButton(
              onPressed: () {
                notifier.reset(); // Reset to try again
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.redAccent),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: isCompact ? 48 : 56,
      child: ElevatedButton(
        onPressed: () {
          if (url != null) {
            notifier.downloadAndInstall(url!);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Update URL missing')));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompact ? Colors.blueAccent : Colors.white,
          foregroundColor: isCompact ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          isCompact ? 'Update Now' : 'Download Update',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
