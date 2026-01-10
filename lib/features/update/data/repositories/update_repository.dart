/// Repository for fetching and caching update configuration.
///
/// This repository handles fetching the remote update config and
/// provides fallback to cached values when network requests fail.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/update_config_model.dart';

/// Repository that manages update configuration fetching and caching.
///
/// The repository:
/// - Fetches remote config from a GitHub-hosted JSON file
/// - Caches successful responses in SharedPreferences
/// - Falls back to cached config when network fails
/// - Validates config before caching
///
/// ## Usage
/// ```dart
/// final repo = UpdateRepository(prefs: await SharedPreferences.getInstance());
/// final config = await repo.fetchConfig();
/// if (config != null) {
///   // Use config
/// }
/// ```
class UpdateRepository {
  /// HTTP client for making network requests.
  final http.Client _client;

  /// SharedPreferences instance for caching.
  final SharedPreferences _prefs;

  /// URL to the remote update configuration JSON.
  ///
  /// This should point to a publicly accessible JSON file
  /// containing the [UpdateConfigModel] structure.
  static const String _kConfigUrl =
      'https://raw.githubusercontent.com/r4khul/unfilter/main/version_config.json';

  /// SharedPreferences key for the cached config JSON.
  static const String _kCachedConfigKey = 'cached_update_config';

  /// SharedPreferences key for the cache timestamp.
  static const String _kCachedTimestampKey = 'cached_update_config_timestamp';

  /// Network request timeout duration.
  static const Duration _kRequestTimeout = Duration(seconds: 10);

  /// Creates an update repository.
  ///
  /// [client] Optional HTTP client (useful for testing).
  /// [prefs] Required SharedPreferences instance for caching.
  UpdateRepository({http.Client? client, required SharedPreferences prefs})
    : _client = client ?? http.Client(),
      _prefs = prefs;

  /// Fetches the remote update configuration.
  ///
  /// Attempts to fetch from the remote URL first. If successful,
  /// the config is cached for offline fallback. If the fetch fails,
  /// returns the cached config (if available).
  ///
  /// Returns null if both remote fetch and cache lookup fail.
  Future<UpdateConfigModel?> fetchConfig() async {
    try {
      final response = await _client
          .get(Uri.parse(_kConfigUrl))
          .timeout(_kRequestTimeout);

      if (response.statusCode == 200) {
        final body = response.body;
        // Validate by parsing before caching
        final json = jsonDecode(body) as Map<String, dynamic>;
        final config = UpdateConfigModel.fromJson(json);

        // Cache valid config
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

    // Fallback to cached config
    return getCachedConfig();
  }

  /// Caches the config JSON string with a timestamp.
  Future<void> _cacheConfig(String jsonBody) async {
    await _prefs.setString(_kCachedConfigKey, jsonBody);
    await _prefs.setInt(
      _kCachedTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Retrieves the cached update configuration.
  ///
  /// Returns null if no cached config exists or if the cached
  /// data is corrupted (in which case it's also cleared).
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

  /// Gets the timestamp when the config was last cached.
  ///
  /// Returns null if no cache timestamp exists.
  DateTime? getCacheTimestamp() {
    final timestamp = _prefs.getInt(_kCachedTimestampKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Clears the cached configuration.
  ///
  /// Useful for debugging or when forcing a fresh fetch.
  Future<void> clearCache() async {
    await _prefs.remove(_kCachedConfigKey);
    await _prefs.remove(_kCachedTimestampKey);
  }
}
