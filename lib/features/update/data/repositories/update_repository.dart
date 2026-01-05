import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_config_model.dart';

class UpdateRepository {
  final http.Client _client;
  final SharedPreferences _prefs;

  // Ideally this URL should be injectable or part of a config file
  static const String _kConfigUrl =
      'https://raw.githubusercontent.com/r4khul/unfilter/main/version_config.json';
  static const String _kCachedConfigKey = 'cached_update_config';
  static const String _kCachedTimestampKey = 'cached_update_config_timestamp';

  UpdateRepository({http.Client? client, required SharedPreferences prefs})
    : _client = client ?? http.Client(),
      _prefs = prefs;

  /// Fetches the remote config.
  /// If successful, caches the result.
  /// If failed, attempts to return the cached version.
  Future<UpdateConfigModel?> fetchConfig() async {
    try {
      final response = await _client
          .get(Uri.parse(_kConfigUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Validate by parsing
        final json = jsonDecode(body) as Map<String, dynamic>;
        final config = UpdateConfigModel.fromJson(json);

        // Cache valid config
        await _prefs.setString(_kCachedConfigKey, body);
        await _prefs.setInt(
          _kCachedTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return config;
      } else {
        debugPrint(
          'Create remote config failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Create remote config fetch failed: $e');
    }

    // Fallback
    return getCachedConfig();
  }

  UpdateConfigModel? getCachedConfig() {
    final jsonStr = _prefs.getString(_kCachedConfigKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UpdateConfigModel.fromJson(json);
      } catch (e) {
        debugPrint('Cached config corrupted: $e');
        // Clear corrupt cache
        _prefs.remove(_kCachedConfigKey);
      }
    }
    return null;
  }

  /// Clears the cached config, mainly for debugging or reset.
  Future<void> clearCache() async {
    await _prefs.remove(_kCachedConfigKey);
    await _prefs.remove(_kCachedTimestampKey);
  }
}
