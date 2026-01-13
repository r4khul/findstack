import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/device_app.dart';
import '../../../scan/domain/entities/scan_progress.dart';
import '../datasources/apps_local_datasource.dart';
import '../../domain/entities/app_usage_point.dart';

class DeviceAppsRepository {
  static const platform = MethodChannel('com.rakhul.unfilter/apps');
  static const eventChannel = EventChannel('com.rakhul.unfilter/scan_progress');

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

    if (_scanInProgress != null && _lastScanIncludedDetails == includeDetails) {
      try {
        return await _scanInProgress!.future;
      } catch (e) {}
    }

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

      if (includeDetails) {
        await _localDataSource.cacheApps(apps);
      }

      completer.complete(apps);
      return apps;
    } on PlatformException catch (e) {
      if (e.code == 'ABORTED') {
        print("Scan was superseded, will retry once...");
        _scanInProgress = null;
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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_scanInProgress == completer) {
          _scanInProgress = null;
        }
      });
    }
  }

  Future<List<DeviceApp>> getAppsDetails(List<String> packageNames) async {
    final allApps = <DeviceApp>[];
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

  Future<List<AppUsagePoint>> getAppUsageHistory(
    String packageName, {
    int? installTime,
  }) async {
    try {
      final List<Object?> result = await platform
          .invokeMethod('getAppUsageHistory', {
            'packageName': packageName,
            if (installTime != null) 'installTime': installTime,
          });
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
    // Also clear the native Kotlin-side cache to ensure fresh data
    try {
      await platform.invokeMethod('clearScanCache');
    } catch (_) {
      // Ignore errors from native cache clear
    }
  }
}
