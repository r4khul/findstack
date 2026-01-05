import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/update_repository.dart';
import '../../domain/update_service.dart';

// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Update Service Provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  throw UnimplementedError('Use updateServiceFutureProvider');
});

final updateServiceFutureProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repo = UpdateRepository(prefs: prefs);
  return UpdateService(repo);
});

// The result of the update check
final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.checkUpdate();
});

// Just the local version (no network)
final currentVersionProvider = FutureProvider<Version>((ref) async {
  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.getCurrentVersion();
});

// Download State definition...
class DownloadState {
  final double progress;
  final bool isDownloading;
  final bool isDone;
  final String? error;
  final String? filePath;

  const DownloadState({
    this.progress = 0.0,
    this.isDownloading = false,
    this.isDone = false,
    this.error,
    this.filePath,
  });

  DownloadState copyWith({
    double? progress,
    bool? isDownloading,
    bool? isDone,
    String? error,
    String? filePath,
  }) {
    return DownloadState(
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isDone: isDone ?? this.isDone,
      error: error,
      filePath: filePath ?? this.filePath,
    );
  }
}

class UpdateDownloadController extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    return const DownloadState();
  }

  Future<void> downloadAndInstall(String url) async {
    if (state.isDownloading) return;

    state = const DownloadState(isDownloading: true);

    try {
      final serviceAsync = ref.read(updateServiceFutureProvider);
      if (!serviceAsync.hasValue) {
        throw Exception('Update service not ready');
      }
      final service = serviceAsync.value!;

      final file = await service.downloadApk(
        url,
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
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
    }
  }

  void reset() {
    state = const DownloadState();
  }
}

final updateDownloadProvider =
    NotifierProvider<UpdateDownloadController, DownloadState>(
      UpdateDownloadController.new,
    );
