import 'package:flutter/services.dart';
import '../../domain/entities/device_app.dart';
import '../../../scan/domain/entities/scan_progress.dart';
import '../../domain/entities/app_usage_point.dart';

class DeviceAppsRepository {
  static const platform = MethodChannel('com.rakhul.findstack/apps');
  static const eventChannel = EventChannel(
    'com.rakhul.findstack/scan_progress',
  );

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

  Future<List<DeviceApp>> getInstalledApps() async {
    try {
      final List<Object?> result = await platform.invokeMethod(
        'getInstalledApps',
      );
      return result
          .cast<Map<Object?, Object?>>()
          .map((e) => DeviceApp.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to get apps: '${e.message}'");
      return [];
    }
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
}
