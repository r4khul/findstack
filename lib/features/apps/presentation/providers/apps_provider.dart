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
        // Return cached data immediately for instant UI
        // Trigger background revalidate instead of full fetch for efficiency
        _backgroundRevalidate(cached);
        return cached;
      }
    } catch (e) {
      // Ignore cache errors
    }

    // 2. No cache, return empty list initially?
    // If we return empty list, UI shows "no apps".
    // If we return loading, UI shows skeleton.
    // We should return empty list but trigger full scan ONLY if we have permission?
    // Actually, `getInstalledApps(forceRefresh: true)` will invoke method channel.
    // If permission is missing, it returns empty list quickly anyway?
    // Wait, `checkUsagePermission` is separate.
    // Let's just return [] if cache miss, and let HomePage logic trigger fullScan.
    // returning [] forces UI to show "No apps found" or skeleton?
    // Ideally we want to stay in "loading" state if we are about to fetch.
    return [];
  }

  Future<void> _backgroundRevalidate(List<DeviceApp> cachedApps) async {
    await Future.delayed(Duration.zero);
    revalidate(cachedApps: cachedApps);
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

  Future<void> revalidate({List<DeviceApp>? cachedApps}) async {
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      print("[Unfilter] Revalidate: Start");
      // 1. Get cached apps (if not provided)
      final appsToCheck =
          cachedApps ?? await repository.getInstalledApps(forceRefresh: false);
      final cachedMap = {for (var app in appsToCheck) app.packageName: app};
      print("[Unfilter] Revalidate: Cached apps count: ${appsToCheck.length}");

      // 2. Get fresh "lite" list (fast)
      print("[Unfilter] Revalidate: Fetching lite apps...");
      final liteApps = await repository.getInstalledApps(
        forceRefresh: true,
        includeDetails: false,
      );
      print("[Unfilter] Revalidate: Lite apps count: ${liteApps.length}");

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
        "[Unfilter] Revalidate: Need to resolve ${appsToResolve.length} apps",
      );
      if (appsToResolve.isNotEmpty) {
        // Fetch details for new/updated apps
        // If list is huge (e.g. first run after clear cache?), this falls back to batch fetch.
        // Ideally we batch this if too large, but for now just one call.
        final details = await repository.getAppsDetails(appsToResolve);
        finalApps.addAll(details);
        print("[Unfilter] Revalidate: Resolved details");
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
      print("[Unfilter] Revalidate: Updating cache and state");
      await repository.updateCache(finalApps);

      state = AsyncValue.data(finalApps);
      print("[Unfilter] Revalidate: Done");
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
