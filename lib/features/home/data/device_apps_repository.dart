import 'package:flutter/services.dart';
import '../domain/device_app.dart';

class DeviceAppsRepository {
  static const platform = MethodChannel('com.rakhul.findstack/apps');

  Future<List<DeviceApp>> getInstalledApps() async {
    try {
      final List<Object?> result = await platform.invokeMethod(
        'getInstalledApps',
      );
      // Filter logic can be done here or UI, but let's return all
      // The native side sends List<Map>
      return result
          .cast<Map<Object?, Object?>>()
          .map((e) => DeviceApp.fromMap(e))
          .toList();
    } on PlatformException catch (e) {
      // In production, use a logger
      print("Failed to get apps: '${e.message}'");
      return [];
    }
  }
}
