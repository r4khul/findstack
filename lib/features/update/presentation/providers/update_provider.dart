/// Riverpod providers for update functionality.
///
/// This file contains all providers related to update checking,
/// downloading, and state management.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/update_repository.dart';
import '../../domain/update_service.dart';
import '../../../../core/services/connectivity_service.dart';

// =============================================================================
// ERROR TYPES
// =============================================================================

/// Error types for update operations.
///
/// These types allow the UI to show appropriate messages and icons
/// based on the specific error that occurred.
enum UpdateErrorType {
  /// Device is offline (no network connectivity).
  offline,

  /// Network available but server unreachable.
  serverUnreachable,

  /// Failed to parse update config JSON.
  parseError,

  /// Download was interrupted (connection lost mid-download).
  downloadInterrupted,

  /// File system error (can't write/read APK file).
  fileSystemError,

  /// APK installation failed.
  installationFailed,

  /// Unknown or generic error.
  unknown,
}

// =============================================================================
// CORE PROVIDERS
// =============================================================================

/// Provider for SharedPreferences instance.
///
/// Used by the update repository for caching configurations.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// Provider for the connectivity service singleton.
///
/// Provides access to network connectivity checking.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for checking current connectivity status.
///
/// Returns a [Future] that resolves to the current [ConnectivityStatus].
final connectivityStatusProvider = FutureProvider<ConnectivityStatus>((
  ref,
) async {
  final service = ref.read(connectivityServiceProvider);
  return service.checkConnectivity();
});

// =============================================================================
// UPDATE SERVICE PROVIDERS
// =============================================================================

/// Placeholder provider for synchronous access to UpdateService.
///
/// Throws [UnimplementedError] - use [updateServiceFutureProvider] instead.
final updateServiceProvider = Provider<UpdateService>((ref) {
  throw UnimplementedError('Use updateServiceFutureProvider');
});

/// Async provider for the UpdateService.
///
/// Creates an [UpdateService] instance with the required dependencies.
/// This is the preferred way to access the update service.
final updateServiceFutureProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repo = UpdateRepository(prefs: prefs);
  return UpdateService(repo);
});

// =============================================================================
// UPDATE CHECK PROVIDER
// =============================================================================

/// Provider for checking if an update is available.
///
/// This provider:
/// 1. First checks network connectivity
/// 2. If offline, returns an error result immediately
/// 3. If online, delegates to [UpdateService.checkUpdate]
///
/// The result includes update status, version info, and any errors.
///
/// ## Usage
/// ```dart
/// final updateResult = ref.watch(updateCheckProvider);
/// updateResult.when(
///   data: (result) => handleResult(result),
///   loading: () => showLoading(),
///   error: (e, s) => showError(e),
/// );
/// ```
final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  // First check connectivity
  final connectivity = ref.read(connectivityServiceProvider);
  final status = await connectivity.checkConnectivity();

  if (status == ConnectivityStatus.offline) {
    return const UpdateCheckResult(
      status: UpdateStatus.unknown,
      error: 'No internet connection. Please connect to WiFi or mobile data.',
      errorType: UpdateErrorType.offline,
    );
  }

  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.checkUpdate();
});

/// Provider for the current app version (no network required).
///
/// Returns the installed app version as a [Version] object.
final currentVersionProvider = FutureProvider<Version>((ref) async {
  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.getCurrentVersion();
});

// =============================================================================
// DOWNLOAD STATE
// =============================================================================

/// State class representing the current download progress.
///
/// Tracks download progress, completion status, errors, and file path.
class DownloadState {
  /// Current download progress (0.0 to 1.0).
  final double progress;

  /// Whether a download is currently in progress.
  final bool isDownloading;

  /// Whether the download has completed successfully.
  final bool isDone;

  /// Error message if the download failed.
  final String? error;

  /// Type of error for appropriate UI messaging.
  final UpdateErrorType? errorType;

  /// Path to the downloaded APK file.
  final String? filePath;

  /// Creates a download state.
  const DownloadState({
    this.progress = 0.0,
    this.isDownloading = false,
    this.isDone = false,
    this.error,
    this.errorType,
    this.filePath,
  });

  /// Whether this is a network-related error.
  ///
  /// When true, the UI should suggest checking the connection.
  bool get isNetworkError =>
      errorType == UpdateErrorType.offline ||
      errorType == UpdateErrorType.serverUnreachable ||
      errorType == UpdateErrorType.downloadInterrupted;

  /// Creates a copy of this state with the specified fields replaced.
  DownloadState copyWith({
    double? progress,
    bool? isDownloading,
    bool? isDone,
    String? error,
    UpdateErrorType? errorType,
    String? filePath,
  }) {
    return DownloadState(
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isDone: isDone ?? this.isDone,
      error: error,
      errorType: errorType,
      filePath: filePath ?? this.filePath,
    );
  }
}

// =============================================================================
// DOWNLOAD CONTROLLER
// =============================================================================

/// Notifier that manages the download state and operations.
///
/// Handles:
/// - Connectivity checks before download
/// - Download progress tracking
/// - Error handling with specific error types
/// - APK installation trigger
///
/// ## Usage
/// ```dart
/// final controller = ref.read(updateDownloadProvider.notifier);
/// controller.downloadAndInstall(url, version);
/// ```
class UpdateDownloadController extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    return const DownloadState();
  }

  /// Starts downloading and installing the update.
  ///
  /// [url] The direct download URL for the APK.
  /// [version] Version string for the filename.
  ///
  /// If already downloaded, triggers installation directly.
  /// Checks connectivity before starting download.
  Future<void> downloadAndInstall(String url, String version) async {
    // Prevent double downloading
    if (state.isDownloading) return;

    // If already downloaded, just install
    if (state.isDone && state.filePath != null) {
      await _installExistingFile();
      return;
    }

    // Check connectivity before starting download
    final connectivityStatus = await _checkConnectivityBeforeDownload();
    if (connectivityStatus == ConnectivityStatus.offline) {
      state = DownloadState(
        error:
            'No internet connection. Please connect to WiFi or mobile data to download the update.',
        errorType: UpdateErrorType.offline,
      );
      return;
    }

    state = const DownloadState(isDownloading: true);

    try {
      await _performDownload(url, version);
    } on SocketException catch (_) {
      _handleSocketException();
    } on FileSystemException catch (e) {
      _handleFileSystemException(e);
    } catch (e) {
      _handleGenericException(e);
    }
  }

  /// Attempts to install an already-downloaded APK.
  Future<void> _installExistingFile() async {
    final file = File(state.filePath!);
    if (await file.exists()) {
      final serviceAsync = ref.read(updateServiceFutureProvider);
      if (serviceAsync.hasValue) {
        try {
          await serviceAsync.value!.installApk(file);
        } catch (e) {
          state = state.copyWith(
            error: 'Installation failed. Please try again.',
            errorType: UpdateErrorType.installationFailed,
          );
        }
      }
    }
  }

  /// Checks connectivity before attempting download.
  Future<ConnectivityStatus> _checkConnectivityBeforeDownload() async {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.checkConnectivity();
  }

  /// Performs the actual download operation.
  Future<void> _performDownload(String url, String version) async {
    final serviceAsync = ref.read(updateServiceFutureProvider);
    if (!serviceAsync.hasValue) {
      throw Exception('Update service not ready');
    }
    final service = serviceAsync.value!;

    final file = await service.downloadApk(
      url,
      version,
      onProgress: (p) {
        state = state.copyWith(progress: p);
      },
    );

    state = state.copyWith(
      isDownloading: false,
      isDone: true,
      progress: 1.0,
      filePath: file.path,
    );

    // Attempt install
    await service.installApk(file);
  }

  /// Handles socket exceptions (network lost during download).
  void _handleSocketException() {
    state = DownloadState(
      error:
          'Connection lost during download. Please check your internet and try again.',
      errorType: UpdateErrorType.downloadInterrupted,
    );
  }

  /// Handles file system exceptions.
  void _handleFileSystemException(FileSystemException e) {
    state = DownloadState(
      error: 'Unable to save update file: ${e.message}',
      errorType: UpdateErrorType.fileSystemError,
    );
  }

  /// Handles generic exceptions with error type detection.
  void _handleGenericException(Object e) {
    final errorMsg = e.toString().toLowerCase();
    UpdateErrorType errorType = UpdateErrorType.unknown;
    String userMessage = 'Download failed. Please try again.';

    if (errorMsg.contains('socket') ||
        errorMsg.contains('connection') ||
        errorMsg.contains('network') ||
        errorMsg.contains('timeout')) {
      errorType = UpdateErrorType.downloadInterrupted;
      userMessage =
          'Connection error. Please check your internet and try again.';
    } else if (errorMsg.contains('permission') ||
        errorMsg.contains('denied') ||
        errorMsg.contains('storage')) {
      errorType = UpdateErrorType.fileSystemError;
      userMessage =
          'Storage permission required. Please check app permissions.';
    }

    state = DownloadState(error: userMessage, errorType: errorType);
  }

  /// Checks connectivity and returns the status.
  ///
  /// Useful for UI to pre-check before retry attempts.
  Future<ConnectivityStatus> checkConnectivity() async {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.checkConnectivity();
  }

  /// Resets the download state to initial values.
  ///
  /// Call before retrying a failed download.
  void reset() {
    state = const DownloadState();
  }
}

/// Provider for the download controller and state.
///
/// ## Usage
/// ```dart
/// // Watch the state
/// final state = ref.watch(updateDownloadProvider);
///
/// // Access the controller
/// final controller = ref.read(updateDownloadProvider.notifier);
/// controller.downloadAndInstall(url, version);
/// ```
final updateDownloadProvider =
    NotifierProvider<UpdateDownloadController, DownloadState>(
      UpdateDownloadController.new,
    );
