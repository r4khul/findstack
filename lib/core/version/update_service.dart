import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'version_models.dart';

/// Service responsible for managing app updates and version checking.
class UpdateService {
  final ShorebirdUpdater _shorebirdUpdater;
  final String _configUrl;

  // Cache the update status to avoid repeated fetches
  AppVersion? _currentVersion;

  UpdateService({
    ShorebirdUpdater? shorebirdUpdater,
    String configUrl =
        'https://raw.githubusercontent.com/r4khul/unfilter/main/version_config.json',
  }) : _shorebirdUpdater = shorebirdUpdater ?? ShorebirdUpdater(),
       _configUrl = configUrl;

  /// Gets the current application version, including Shorebird patch if applicable.
  Future<AppVersion> getCurrentVersion() async {
    if (_currentVersion != null) return _currentVersion!;

    final packageInfo = await PackageInfo.fromPlatform();
    // Assuming packageInfo.version is x.y.z
    final nativeVersion = AppVersion.parse(
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );

    // Check for Shorebird patch
    int? patchNumber;
    try {
      final patch = await _shorebirdUpdater.readCurrentPatch();
      patchNumber = patch?.number;
    } catch (e) {
      debugPrint('Shorebird not available or failed: $e');
    }

    _currentVersion = nativeVersion.withShorebirdPatch(patchNumber);
    return _currentVersion!;
  }

  /// Checks for updates against the remote configuration.
  Future<UpdateState> checkUpdate() async {
    try {
      final current = await getCurrentVersion();
      final config = await _fetchConfig();

      // 1. Check Force Update (Blocking)
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

      // 2. Check Soft Update (Optional)
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

  /// Trigger a Shorebird background update check/download.
  Future<void> checkForShorebirdUpdate() async {
    try {
      final status = await _shorebirdUpdater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _shorebirdUpdater.update();
      }
    } catch (e) {
      debugPrint('Shorebird update check failed: $e');
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
