import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/update_repository.dart';
import '../../domain/update_service.dart';
import '../../../../core/services/connectivity_service.dart';

/// Error types for update operations - allows UI to show appropriate messages
enum UpdateErrorType {
  /// Device is offline (no network connectivity)
  offline,

  /// Network available but server unreachable
  serverUnreachable,

  /// Failed to parse update config
  parseError,

  /// Download was interrupted
  downloadInterrupted,

  /// File system error (can't write/read APK)
  fileSystemError,

  /// Installation failed
  installationFailed,

  /// Unknown or generic error
  unknown,
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// Connectivity service provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for checking current connectivity status
final connectivityStatusProvider = FutureProvider<ConnectivityStatus>((
  ref,
) async {
  final service = ref.read(connectivityServiceProvider);
  return service.checkConnectivity();
});

/// Update Service Provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  throw UnimplementedError('Use updateServiceFutureProvider');
});

final updateServiceFutureProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repo = UpdateRepository(prefs: prefs);
  return UpdateService(repo);
});

/// The result of the update check - now with connectivity awareness
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

/// Just the local version (no network)
final currentVersionProvider = FutureProvider<Version>((ref) async {
  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.getCurrentVersion();
});

/// Download State definition with enhanced error handling
class DownloadState {
  final double progress;
  final bool isDownloading;
  final bool isDone;
  final String? error;
  final UpdateErrorType? errorType;
  final String? filePath;

  const DownloadState({
    this.progress = 0.0,
    this.isDownloading = false,
    this.isDone = false,
    this.error,
    this.errorType,
    this.filePath,
  });

  /// Whether this is a network-related error (user should check connection)
  bool get isNetworkError =>
      errorType == UpdateErrorType.offline ||
      errorType == UpdateErrorType.serverUnreachable ||
      errorType == UpdateErrorType.downloadInterrupted;

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

class UpdateDownloadController extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    return const DownloadState();
  }

  Future<void> downloadAndInstall(String url, String version) async {
    // Prevent double downloading
    if (state.isDownloading) return;

    // If already downloaded, just install
    if (state.isDone && state.filePath != null) {
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
          return;
        }
      }
    }

    // Check connectivity before starting download
    final connectivity = ref.read(connectivityServiceProvider);
    final connectivityStatus = await connectivity.checkConnectivity();

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
    } on SocketException catch (_) {
      // Network was lost during download
      state = DownloadState(
        error:
            'Connection lost during download. Please check your internet and try again.',
        errorType: UpdateErrorType.downloadInterrupted,
      );
    } on FileSystemException catch (e) {
      state = DownloadState(
        error: 'Unable to save update file: ${e.message}',
        errorType: UpdateErrorType.fileSystemError,
      );
    } catch (e) {
      // Determine error type from exception message
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
  }

  /// Checks connectivity and provides status
  Future<ConnectivityStatus> checkConnectivity() async {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.checkConnectivity();
  }

  void reset() {
    state = const DownloadState();
  }
}

final updateDownloadProvider =
    NotifierProvider<UpdateDownloadController, DownloadState>(
      UpdateDownloadController.new,
    );
