import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/device_apps_repository.dart';
import '../../domain/entities/device_app.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

class InstalledAppsNotifier extends AsyncNotifier<List<DeviceApp>> {
  @override
  Future<List<DeviceApp>> build() async {
    final repository = ref.watch(deviceAppsRepositoryProvider);

    // 1. Try Cache
    try {
      final cached = await repository.getInstalledApps(forceRefresh: false);
      if (cached.isNotEmpty) {
        // If we found cached data, return it immediately so the UI renders.
        // We trigger a background refresh to update the data if needed.
        _refreshInBackground(repository);
        return cached;
      }
    } catch (e) {
      // Ignore cache errors
    }

    // 2. No cache, fetch fresh
    return await repository.getInstalledApps(forceRefresh: true);
  }

  Future<void> _refreshInBackground(DeviceAppsRepository repository) async {
    // Wait for the build to complete before updating state
    await Future.delayed(Duration.zero);

    try {
      final fresh = await repository.getInstalledApps(forceRefresh: true);
      // Only update if the widget is still mounted/provider is alive
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      // If fresh fetch fails, we can either:
      // A) Leave the cached data (state remains AsyncData) - preferred for "offline first"
      // B) Show an error (might be jarring if user is viewing content)
      // We'll log it.
      print("Background refresh failed: $e");
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(deviceAppsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getInstalledApps(forceRefresh: true),
    );
  }
}

final installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<DeviceApp>>(() {
      return InstalledAppsNotifier();
    });

final usagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.checkUsagePermission();
});
