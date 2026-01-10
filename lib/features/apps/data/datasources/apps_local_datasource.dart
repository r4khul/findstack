import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/device_app.dart';

import 'package:flutter/foundation.dart';

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
    final jsonString = await compute(_encodeApps, apps);
    await file.writeAsString(jsonString);
  }

  Future<List<DeviceApp>> getCachedApps() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      return await compute(_decodeApps, content);
    } catch (e) {
      print('Error reading cache: $e');
      return [];
    }
  }

  static String _encodeApps(List<DeviceApp> apps) {
    final jsonList = apps.map((app) {
      final map = app.toMap();
      return map;
    }).toList();
    return json.encode(jsonList);
  }

  static List<DeviceApp> _decodeApps(String content) {
    final List<dynamic> jsonList = json.decode(content);
    return jsonList.map((e) {
      final map = e as Map<String, dynamic>;
      if (map['icon'] is List) {
        map['icon'] = Uint8List.fromList((map['icon'] as List).cast<int>());
      }
      return DeviceApp.fromMap(map);
    }).toList();
  }

  Future<void> clearCache() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
