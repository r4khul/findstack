import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/device_app.dart';
import '../../../scan/domain/entities/scan_progress.dart';
import '../datasources/apps_local_datasource.dart';
import '../../domain/entities/app_usage_point.dart';

class DeviceAppsRepository {
  static const platform = MethodChannel('com.rakhul.unfilter/apps');
  static const eventChannel = EventChannel('com.rakhul.unfilter/scan_progress');

  // Mutex to prevent concurrent scan requests
  Completer<List<DeviceApp>>? _scanInProgress;
  bool _lastScanIncludedDetails = false;

  Stream<ScanProgress> get scanProgressStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return ScanProgress.fromMap(event);
      }
      return ScanProgress(
        status: "Initializing",
        percent: 0,
        processedCount: 0,
        totalCount: 0,
      );
    });
  }

  final AppsLocalDataSource _localDataSource = AppsLocalDataSource();

  // Expose cache stream directly if needed, but for SWR via Riverpod, we just expose methods.

  Future<List<DeviceApp>> getInstalledApps({
    bool forceRefresh = false,
    bool includeDetails = true,
  }) async {
    if (!forceRefresh && includeDetails) {
      final cachedApps = await _localDataSource.getCachedApps();
      if (cachedApps.isNotEmpty) {
        return cachedApps;
      }
    }

    // If a scan with same detail level is already in progress, wait for it
    if (_scanInProgress != null && _lastScanIncludedDetails == includeDetails) {
      try {
        return await _scanInProgress!.future;
      } catch (e) {
        // If the in-progress scan failed, continue to start a new one
      }
    }

    // Start a new scan with mutex
    final completer = Completer<List<DeviceApp>>();
    _scanInProgress = completer;
    _lastScanIncludedDetails = includeDetails;

    try {
      final List<Object?> result = await platform.invokeMethod(
        'getInstalledApps',
        {'includeDetails': includeDetails},
      );
      final apps = result
          .cast<Map<Object?, Object?>>()
          .map((e) => DeviceApp.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Only cache if we have details
      if (includeDetails) {
        await _localDataSource.cacheApps(apps);
      }

      completer.complete(apps);
      return apps;
    } on PlatformException catch (e) {
      // Special handling for ABORTED - this is a soft failure
      if (e.code == 'ABORTED') {
        print("Scan was superseded, will retry once...");
        // Clear the mutex and retry once
        _scanInProgress = null;
        // Small delay before retry
        await Future.delayed(const Duration(milliseconds: 200));
        return getInstalledApps(
          forceRefresh: forceRefresh,
          includeDetails: includeDetails,
        );
      }
      print("Failed to get apps: '${e.message}'");
      completer.completeError(e);
      return [];
    } catch (e) {
      print("Failed to get apps: '$e'");
      completer.completeError(e);
      return [];
    } finally {
      // Clear the mutex after a short delay to allow result sharing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_scanInProgress == completer) {
          _scanInProgress = null;
        }
      });
    }
  }

  Future<List<DeviceApp>> getAppsDetails(List<String> packageNames) async {
    final allApps = <DeviceApp>[];
    // Batch to prevent TransactionTooLargeException (Binder 1MB limit)
    // 20 apps * 20KB (approx icon size) = ~400KB. Safe margin.
    // Batch to prevent TransactionTooLargeException (Binder 1MB limit)
    // Decreased to 10 to ensure safety with larger icons/metadata
    const int batchSize = 10;

    for (var i = 0; i < packageNames.length; i += batchSize) {
      final end = (i + batchSize < packageNames.length)
          ? i + batchSize
          : packageNames.length;
      final batch = packageNames.sublist(i, end);

      try {
        final List<Object?> result = await platform.invokeMethod(
          'getAppsDetails',
          {'packageNames': batch},
        );

        allApps.addAll(
          result.cast<Map<Object?, Object?>>().map(
            (e) => DeviceApp.fromMap(Map<String, dynamic>.from(e)),
          ),
        );
      } on PlatformException catch (e) {
        print("Failed to get app details chunk: '${e.message}'");
        // Continue with other chunks even if one fails
      }
    }
    return allApps;
  }

  Future<bool> checkUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod('checkUsagePermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'");
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'");
    }
  }

  Future<bool> checkInstallPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkInstallPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check install permission: '${e.message}'");
      return false;
    }
  }

  Future<void> requestInstallPermission() async {
    try {
      await platform.invokeMethod('requestInstallPermission');
    } on PlatformException catch (e) {
      print("Failed to request install permission: '${e.message}'");
    }
  }

  Future<List<AppUsagePoint>> getAppUsageHistory(String packageName) async {
    try {
      final List<Object?> result = await platform.invokeMethod(
        'getAppUsageHistory',
        {'packageName': packageName},
      );
      return result
          .cast<Map<Object?, Object?>>()
          .map((e) => AppUsagePoint.fromMap(e))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to get usage history: '${e.message}'");
      return [];
    }
  }

  Future<void> updateCache(List<DeviceApp> apps) async {
    await _localDataSource.cacheApps(apps);
  }

  Future<void> clearCache() async {
    await _localDataSource.clearCache();
  }
}
