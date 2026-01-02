import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/device_app.dart';

class AppsLocalDataSource {
  static const _fileName = 'apps_cache.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> cacheApps(List<DeviceApp> apps) async {
    final file = await _localFile;
    final jsonList = apps.map((app) {
      final map = app.toMap();
      // Remove icon from cache to save space/performance if it's large binary data?
      // Or keep it? If it's Uint8List, verify serialization.
      // jsonEncode handles List<int> but it might be large.
      // For now, let's keep it but be aware.
      // Actually, standard jsonEncode encodes lists as arrays.
      return map;
    }).toList();

    // We need to handle Uint8List encoding if present.
    // jsonEncode automatically converts lists, but let's be explicit to avoid issues if we want to optimize later.

    await file.writeAsString(json.encode(jsonList));
  }

  Future<List<DeviceApp>> getCachedApps() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);

      return jsonList.map((e) {
        // Handle converting List<dynamic> back to primitives if needed,
        // but DeviceApp.fromMap expects Map<Object?, Object?>.
        // JSON map is Map<String, dynamic>.
        // Check if 'icon' needs special handling (List<int> to Uint8List).
        final map = e as Map<String, dynamic>;
        if (map['icon'] is List) {
          map['icon'] = Uint8List.fromList((map['icon'] as List).cast<int>());
        }
        return DeviceApp.fromMap(map);
      }).toList();
    } catch (e) {
      print('Error reading cache: $e');
      return [];
    }
  }
}
