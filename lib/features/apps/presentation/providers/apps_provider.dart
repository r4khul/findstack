import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/device_apps_repository.dart';
import '../../domain/entities/device_app.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

class InstalledAppsNotifier extends AsyncNotifier<List<DeviceApp>> {
  // Prevent concurrent scans from Flutter side
  bool _isScanInProgress = false;

  @override
  Future<List<DeviceApp>> build() async {
    final repository = ref.watch(deviceAppsRepositoryProvider);

    // 1. Try Cache
    try {
      final cached = await repository.getInstalledApps(forceRefresh: false);
      if (cached.isNotEmpty) {
        // Return cached data immediately for instant UI
        // NOTE: We intentionally do NOT trigger background revalidate here
        // to prevent race conditions during initial scan. The user can
        // manually trigger a rescan from the home page if needed.
        return cached;
      }
    } catch (e) {
      // Ignore cache errors
    }

    // 2. No cache, return empty list initially
    // Let ScanPage or HomePage trigger fullScan explicitly
    return [];
  }

  Future<void> fullScan() async {
    // Prevent concurrent scans
    if (_isScanInProgress) {
      print("[Unfilter] fullScan: Scan already in progress, skipping");
      return;
    }

    _isScanInProgress = true;
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      state = const AsyncValue.loading();
      // Clear cache first
      await repository.clearCache();
      // Then fetch fresh
      state = await AsyncValue.guard(
        () => repository.getInstalledApps(forceRefresh: true),
      );
    } finally {
      _isScanInProgress = false;
    }
  }

  /// Resync a single app by fetching fresh details.
  /// Returns the updated app data, or null if failed.
  Future<DeviceApp?> resyncApp(String packageName) async {
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      print("[Unfilter] ResyncApp: Fetching details for $packageName");

      // Fetch fresh details for this single app
      final details = await repository.getAppsDetails([packageName]);

      if (details.isEmpty) {
        print("[Unfilter] ResyncApp: No details returned for $packageName");
        return null;
      }

      final updatedApp = details.first;
      print(
        "[Unfilter] ResyncApp: Got updated details for ${updatedApp.appName}",
      );

      // Update the state with the new app data
      final currentApps = switch (state) {
        AsyncData(:final value) => value,
        _ => <DeviceApp>[],
      };
      final updatedApps = currentApps.map((app) {
        if (app.packageName == packageName) {
          return updatedApp;
        }
        return app;
      }).toList();

      // Update cache and state
      await repository.updateCache(updatedApps);
      state = AsyncValue.data(updatedApps);

      print("[Unfilter] ResyncApp: Updated cache and state");
      return updatedApp;
    } catch (e) {
      print("[Unfilter] ResyncApp: Failed - $e");
      return null;
    }
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
