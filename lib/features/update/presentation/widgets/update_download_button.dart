library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/update_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import 'constants.dart';

class UpdateDownloadButton extends ConsumerStatefulWidget {
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
  ConsumerState<UpdateDownloadButton> createState() =>
      _UpdateDownloadButtonState();
}

class _UpdateDownloadButtonState extends ConsumerState<UpdateDownloadButton> {
  bool _isCheckingConnectivity = false;

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(updateDownloadProvider);
    final theme = Theme.of(context);

    ref.listen<DownloadState>(updateDownloadProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        _showNetworkErrorSnackbar(context, theme, next.errorType);
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          height: widget.isCompact
              ? UpdateSizes.buttonHeightCompact
              : UpdateSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: (_isCheckingConnectivity || downloadState.isDownloading)
                ? null
                : _handleDownload,
            style: _buildButtonStyle(theme, downloadState),
            child: _buildButtonContent(theme, downloadState),
          ),
        ),
        if (downloadState.error != null && !downloadState.isDownloading) ...[
          const SizedBox(height: UpdateSpacing.md),
          Text(
            downloadState.isNetworkError
                ? 'Connect to internet to download'
                : 'Tap to try again',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(
                UpdateOpacity.veryHigh,
              ),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  ButtonStyle _buildButtonStyle(ThemeData theme, DownloadState downloadState) {
    final bgColor = _getBackgroundColor(theme, downloadState);

    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: bgColor.withOpacity(0.6),
      disabledForegroundColor: Colors.white70,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'UncutSans',
        letterSpacing: -0.5,
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme, DownloadState downloadState) {
    if (downloadState.isDone) {
      return UpdateColors.installGreen;
    } else if (downloadState.error != null) {
      return downloadState.isNetworkError
          ? Colors.orange.shade700
          : theme.colorScheme.error;
    }
    return theme.colorScheme.primary;
  }

  Widget _buildButtonContent(ThemeData theme, DownloadState downloadState) {
    if (_isCheckingConnectivity) {
      return _buildCheckingContent(theme);
    } else if (downloadState.isDownloading) {
      return _buildDownloadingContent(theme, downloadState);
    } else if (downloadState.isDone) {
      return _buildDoneContent(theme);
    } else if (downloadState.error != null) {
      return _buildErrorContent(theme, downloadState);
    }
    return _buildIdleContent(theme);
  }

  Widget _buildCheckingContent(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: UpdateSizes.iconSizeSmall,
          height: UpdateSizes.iconSizeSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: UpdateSpacing.md),
        Text(
          'Checking...',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
            fontFamily: 'UncutSans',
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingContent(
    ThemeData theme,
    DownloadState downloadState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: UpdateSizes.iconSizeSmall,
          height: UpdateSizes.iconSizeSmall,
          child: CircularProgressIndicator(
            value: downloadState.progress,
            strokeWidth: 2.5,
            color: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.onPrimary.withOpacity(
              UpdateOpacity.light,
            ),
          ),
        ),
        const SizedBox(width: UpdateSpacing.md),
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
  }

  Widget _buildDoneContent(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.system_update,
          size: UpdateSizes.iconSize,
          color: theme.colorScheme.onPrimary,
        ),
        const SizedBox(width: UpdateSpacing.sm),
        Text(
          'Install Update',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(ThemeData theme, DownloadState downloadState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          downloadState.isNetworkError
              ? Icons.wifi_off_rounded
              : Icons.refresh_rounded,
          size: UpdateSizes.iconSizeSmall,
          color: theme.colorScheme.onError,
        ),
        const SizedBox(width: UpdateSpacing.sm),
        Text(
          downloadState.isNetworkError ? 'Check Connection' : 'Retry',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onError,
          ),
        ),
      ],
    );
  }

  Widget _buildIdleContent(ThemeData theme) {
    return Text(
      'Update Now',
      style: TextStyle(
        fontSize: widget.isCompact ? 14 : 16,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _handleDownload() async {
    if (widget.url == null) return;

    final notifier = ref.read(updateDownloadProvider.notifier);
    final downloadState = ref.read(updateDownloadProvider);

    if (downloadState.isDone && downloadState.filePath != null) {
      final file = File(downloadState.filePath!);
      ref.read(updateServiceFutureProvider).value?.installApk(file);
      return;
    }

    if (downloadState.error != null) {
      setState(() => _isCheckingConnectivity = true);

      final connectivity = await notifier.checkConnectivity();

      if (!mounted) return;
      setState(() => _isCheckingConnectivity = false);

      if (connectivity == ConnectivityStatus.offline) {
        _showNetworkErrorSnackbar(
          context,
          Theme.of(context),
          UpdateErrorType.offline,
        );
        return;
      }

      notifier.reset();
    }

    notifier.downloadAndInstall(widget.url!, widget.version);
  }

  void _showNetworkErrorSnackbar(
    BuildContext context,
    ThemeData theme,
    UpdateErrorType? errorType,
  ) {
    final message = _getErrorMessage(errorType);
    final icon = _getErrorIcon(errorType);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
          child: BackdropFilter(
            filter: standardBlurFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UpdateSpacing.standard,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? UpdateColors.darkCardBackground.withOpacity(0.95)
                    : UpdateColors.lightSnackbarBackground.withOpacity(0.95),
                borderRadius: BorderRadius.circular(
                  UpdateBorderRadius.standard,
                ),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(
                    UpdateOpacity.medium,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(UpdateSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: UpdateSizes.iconSizeSmall,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: UpdateSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getErrorTitle(errorType),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(
          horizontal: UpdateSpacing.standard,
          vertical: UpdateSpacing.md,
        ),
      ),
    );
  }

  String _getErrorTitle(UpdateErrorType? errorType) {
    switch (errorType) {
      case UpdateErrorType.offline:
        return 'No Internet';
      case UpdateErrorType.serverUnreachable:
        return 'Server Unavailable';
      case UpdateErrorType.downloadInterrupted:
        return 'Connection Lost';
      case UpdateErrorType.fileSystemError:
        return 'Storage Error';
      case UpdateErrorType.installationFailed:
        return 'Installation Failed';
      default:
        return 'Download Failed';
    }
  }

  String _getErrorMessage(UpdateErrorType? errorType) {
    switch (errorType) {
      case UpdateErrorType.offline:
        return 'Connect to WiFi or mobile data to download.';
      case UpdateErrorType.serverUnreachable:
        return 'Update server is temporarily unavailable.';
      case UpdateErrorType.downloadInterrupted:
        return 'Please check your connection and try again.';
      case UpdateErrorType.fileSystemError:
        return 'Check storage space and permissions.';
      case UpdateErrorType.installationFailed:
        return 'Please try installing again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  IconData _getErrorIcon(UpdateErrorType? errorType) {
    switch (errorType) {
      case UpdateErrorType.offline:
        return Icons.wifi_off_rounded;
      case UpdateErrorType.serverUnreachable:
        return Icons.cloud_off_rounded;
      case UpdateErrorType.downloadInterrupted:
        return Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;
      case UpdateErrorType.fileSystemError:
        return Icons.storage_rounded;
      case UpdateErrorType.installationFailed:
        return Icons.error_outline_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
