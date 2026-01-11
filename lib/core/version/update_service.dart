import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'version_models.dart';

class UpdateService {
  final String _configUrl;

  AppVersion? _currentVersion;

  UpdateService({
    String configUrl =
        'https://raw.githubusercontent.com/r4khul/unfilter/main/version_config.json',
  }) : _configUrl = configUrl;

  Future<AppVersion> getCurrentVersion() async {
    if (_currentVersion != null) return _currentVersion!;

    final packageInfo = await PackageInfo.fromPlatform();
    final nativeVersion = AppVersion.parse(
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );

    _currentVersion = nativeVersion;
    return _currentVersion!;
  }

  Future<UpdateState> checkUpdate() async {
    try {
      final current = await getCurrentVersion();
      final config = await _fetchConfig();

      if (current.isLowerThan(
        config.minSupportedNativeVersion,
        ignoreBuild: true,
      )) {
        return UpdateState(
          status: AppUpdateStatus.forceUpdate,
          config: config,
          currentVersion: current,
        );
      }

      if (current.isLowerThan(config.latestNativeVersion, ignoreBuild: true)) {
        return UpdateState(
          status: AppUpdateStatus.softUpdate,
          config: config,
          currentVersion: current,
        );
      }

      return UpdateState(
        status: AppUpdateStatus.upToDate,
        config: config,
        currentVersion: current,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return UpdateState(
        status: AppUpdateStatus.upToDate,
        config: null,
        currentVersion:
            _currentVersion ??
            const AppVersion(major: 0, minor: 0, patch: 0, build: 0),
        error: e.toString(),
      );
    }
  }

  Future<UpdateConfig> _fetchConfig() async {
    final response = await http
        .get(Uri.parse(_configUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return UpdateConfig.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load version config: ${response.statusCode}');
    }
  }
}

class UpdateState {
  final AppUpdateStatus status;
  final UpdateConfig? config;
  final AppVersion currentVersion;
  final String? error;

  UpdateState({
    required this.status,
    this.config,
    required this.currentVersion,
    this.error,
  });
}
