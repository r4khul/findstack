/// A stateful button for downloading and installing app updates.
///
/// This button handles the complete download flow including:
/// - Connectivity checks before download
/// - Progress indication during download
/// - Error handling with appropriate UI feedback
/// - Installation trigger when download completes
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/update_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import 'constants.dart';

/// A button that manages the update download and installation flow.
///
/// The button displays different states:
/// - **Idle**: "Update Now" - ready to start download
/// - **Checking**: Shows spinner while checking connectivity
/// - **Downloading**: Shows progress percentage
/// - **Done**: "Install Update" - ready to install
/// - **Error**: Shows retry option with appropriate messaging
///
/// ## Usage
/// ```dart
/// UpdateDownloadButton(
///   url: 'https://example.com/app.apk',
///   version: '1.2.0',
///   isFullWidth: true,
/// )
/// ```
///
/// ## Error Handling
/// The button automatically shows snackbars for network errors and
/// provides contextual retry options based on the error type.
class UpdateDownloadButton extends ConsumerStatefulWidget {
  /// The URL to download the APK from.
  final String? url;

  /// The version string for display and file naming.
  final String version;

  /// Whether to use compact styling (smaller height).
  final bool isCompact;

  /// Whether the button should expand to full width.
  final bool isFullWidth;

  /// Creates an update download button.
  ///
  /// [url] is the download URL for the APK.
  /// [version] is the version string to display.
  /// [isCompact] uses smaller button height when true.
  /// [isFullWidth] expands button to full width when true.
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

    // Listen for error state changes to show snackbar
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
        // Subtle error message below button
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

  /// Builds the button style based on current download state.
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

  /// Gets the appropriate background color based on state.
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

  /// Builds the button content based on current state.
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

  /// Builds content for connectivity checking state.
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

  /// Builds content for downloading state with progress.
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

  /// Builds content for download complete state.
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

  /// Builds content for error state.
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

  /// Builds content for idle state.
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

  /// Handles the download button press.
  Future<void> _handleDownload() async {
    if (widget.url == null) return;

    final notifier = ref.read(updateDownloadProvider.notifier);
    final downloadState = ref.read(updateDownloadProvider);

    // If already done, just install
    if (downloadState.isDone && downloadState.filePath != null) {
      final file = File(downloadState.filePath!);
      ref.read(updateServiceFutureProvider).value?.installApk(file);
      return;
    }

    // If had an error, check connectivity first before retrying
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

    // Start download
    notifier.downloadAndInstall(widget.url!, widget.version);
  }

  /// Shows a styled snackbar for network errors.
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

  /// Gets the error title based on error type.
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

  /// Gets the error message based on error type.
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

  /// Gets the appropriate icon based on error type.
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
