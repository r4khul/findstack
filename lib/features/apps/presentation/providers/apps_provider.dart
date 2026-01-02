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

  Future<void> fullScan() async {
    final repository = ref.read(deviceAppsRepositoryProvider);
    state = const AsyncValue.loading();
    // Clear cache first
    await repository.clearCache();
    // Then fetch fresh
    state = await AsyncValue.guard(
      () => repository.getInstalledApps(forceRefresh: true),
    );
  }

  Future<void> revalidate() async {
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      print("[FindStack] Revalidate: Start");
      // 1. Get cached apps
      final cachedApps = await repository.getInstalledApps(forceRefresh: false);
      final cachedMap = {for (var app in cachedApps) app.packageName: app};
      print("[FindStack] Revalidate: Cached apps count: ${cachedApps.length}");

      // 2. Get fresh "lite" list (fast)
      print("[FindStack] Revalidate: Fetching lite apps...");
      final liteApps = await repository.getInstalledApps(
        forceRefresh: true,
        includeDetails: false,
      );
      print("[FindStack] Revalidate: Lite apps count: ${liteApps.length}");

      final finalApps = <DeviceApp>[];
      final appsToResolve = <String>[];

      for (var liteApp in liteApps) {
        final cached = cachedMap[liteApp.packageName];
        // Check update time.
        if (cached != null && cached.updateDate == liteApp.updateDate) {
          finalApps.add(cached);
        } else {
          // New or Updated app
          appsToResolve.add(liteApp.packageName);
        }
      }

      // 3. Resolve missing details
      print(
        "[FindStack] Revalidate: Need to resolve ${appsToResolve.length} apps",
      );
      if (appsToResolve.isNotEmpty) {
        // Fetch details for new/updated apps
        // If list is huge (e.g. first run after clear cache?), this falls back to batch fetch.
        // Ideally we batch this if too large, but for now just one call.
        final details = await repository.getAppsDetails(appsToResolve);
        finalApps.addAll(details);
        print("[FindStack] Revalidate: Resolved details");
      }

      // 4. Update Cache & State
      // We manually cache here because `getInstalledApps` only caches during full detail fetch.
      // We need to access the local data source directly or expose a cache method?
      // Repository `getInstalledApps` calls `cacheApps` if `includeDetails` is true.
      // But we constructed `finalApps` manually.
      // We should add a `saveToCache` method to repository or just call a method.
      // Let's modify repository to allow saving?
      // Actually `DeviceAppsRepository` has `_localDataSource` private.
      // Let's just assume for now we don't save to file?
      // No, we MUST save to file otherwise next load is empty.
      // I will add `updateCache` to repository in next step.
      print("[FindStack] Revalidate: Updating cache and state");
      await repository.updateCache(finalApps);

      state = AsyncValue.data(finalApps);
      print("[FindStack] Revalidate: Done");
    } catch (e) {
      print("Revalidate failed: $e");
      // Fallback to full refresh if smart revalidate fails?
      // state = await AsyncValue.guard(() => repository.getInstalledApps(forceRefresh: true));
    }
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
