library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/update_config_model.dart';

class UpdateRepository {
  final http.Client _client;

  final SharedPreferences _prefs;

  static const String _kConfigUrl =
      'https://raw.githubusercontent.com/r4khul/unfilter/main/version_config.json';

  static const String _kCachedConfigKey = 'cached_update_config';

  static const String _kCachedTimestampKey = 'cached_update_config_timestamp';

  static const Duration _kRequestTimeout = Duration(seconds: 10);

  UpdateRepository({http.Client? client, required SharedPreferences prefs})
    : _client = client ?? http.Client(),
      _prefs = prefs;

  Future<UpdateConfigModel?> fetchConfig() async {
    try {
      final response = await _client
          .get(Uri.parse(_kConfigUrl))
          .timeout(_kRequestTimeout);

      if (response.statusCode == 200) {
        final body = response.body;
        final json = jsonDecode(body) as Map<String, dynamic>;
        final config = UpdateConfigModel.fromJson(json);

        await _cacheConfig(body);

        return config;
      } else {
        debugPrint(
          'Update config fetch failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Update config fetch failed: $e');
    }

    return getCachedConfig();
  }

  Future<void> _cacheConfig(String jsonBody) async {
    await _prefs.setString(_kCachedConfigKey, jsonBody);
    await _prefs.setInt(
      _kCachedTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  UpdateConfigModel? getCachedConfig() {
    final jsonStr = _prefs.getString(_kCachedConfigKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UpdateConfigModel.fromJson(json);
      } catch (e) {
        debugPrint('Cached config corrupted: $e');
        _prefs.remove(_kCachedConfigKey);
      }
    }
    return null;
  }

  DateTime? getCacheTimestamp() {
    final timestamp = _prefs.getInt(_kCachedTimestampKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> clearCache() async {
    await _prefs.remove(_kCachedConfigKey);
    await _prefs.remove(_kCachedTimestampKey);
  }
}
