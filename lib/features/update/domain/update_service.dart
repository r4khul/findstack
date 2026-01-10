/// Domain service for checking and managing app updates.
///
/// This service provides the core business logic for:
/// - Checking if an update is available
/// - Downloading APK files
/// - Installing updates
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import '../data/models/update_config_model.dart';
import '../data/repositories/update_repository.dart';
import '../presentation/providers/update_provider.dart' show UpdateErrorType;

/// Possible update statuses after checking.
enum UpdateStatus {
  /// The app is up to date - no update needed.
  upToDate,

  /// A soft update is available - user can skip.
  softUpdate,

  /// A force update is required - user cannot skip.
  forceUpdate,

  /// Unable to determine update status (error occurred).
  unknown,
}

/// The result of an update check operation.
///
/// Contains the update status, configuration details, and any errors.
class UpdateCheckResult {
  /// The determined update status.
  final UpdateStatus status;

  /// The remote update configuration (null if fetch failed).
  final UpdateConfigModel? config;

  /// The current app version.
  final Version? currentVersion;

  /// Optional error message if the check failed.
  final String? error;

  /// Optional error type for UI display.
  final UpdateErrorType? errorType;

  /// Creates an update check result.
  const UpdateCheckResult({
    required this.status,
    this.config,
    this.currentVersion,
    this.error,
    this.errorType,
  });
}

/// Service that handles app update operations.
///
/// This service is responsible for:
/// - Determining the current app version
/// - Fetching remote update configuration
/// - Comparing versions to determine update availability
/// - Downloading APK files with progress reporting
/// - Triggering APK installation
///
/// ## Version Comparison Logic
/// 1. If current < minSupported → Force Update
/// 2. If current < latest && forceUpdate flag → Force Update
/// 3. If current < latest → Soft Update
/// 4. Otherwise → Up to Date
///
/// ## Usage
/// ```dart
/// final service = UpdateService(repository);
/// final result = await service.checkUpdate();
///
/// if (result.status == UpdateStatus.forceUpdate) {
///   // Show force update screen
/// }
/// ```
class UpdateService {
  /// The repository for fetching update configuration.
  final UpdateRepository _repository;

  /// Creates an update service with the given repository.
  UpdateService(this._repository);

  /// Gets the current app version from package info.
  ///
  /// Returns a [Version] object that includes the build number
  /// if available (e.g., "1.2.3+42").
  Future<Version> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    String versionString = packageInfo.version;
    if (packageInfo.buildNumber.isNotEmpty) {
      versionString = '$versionString+${packageInfo.buildNumber}';
    }
    return Version.parse(versionString);
  }

  /// Checks if an update is available.
  ///
  /// Fetches the remote configuration and compares versions
  /// to determine the appropriate update status.
  ///
  /// Returns an [UpdateCheckResult] with:
  /// - [UpdateStatus.forceUpdate] if current version is below minimum
  /// - [UpdateStatus.softUpdate] if a newer version is available
  /// - [UpdateStatus.upToDate] if on the latest version
  /// - [UpdateStatus.unknown] if an error occurred
  Future<UpdateCheckResult> checkUpdate() async {
    try {
      final config = await _repository.fetchConfig();
      if (config == null) {
        return const UpdateCheckResult(status: UpdateStatus.unknown);
      }

      final currentVersion = await getCurrentVersion();

      // 1. Critical Check: Min Supported Version
      if (_isLowerThan(currentVersion, config.minSupportedNativeVersion)) {
        return UpdateCheckResult(
          status: UpdateStatus.forceUpdate,
          config: config,
          currentVersion: currentVersion,
        );
      }

      // 2. Check for Soft Update
      if (_isLowerThan(currentVersion, config.latestNativeVersion)) {
        // Check if forced via flag
        if (config.forceUpdate) {
          return UpdateCheckResult(
            status: UpdateStatus.forceUpdate,
            config: config,
            currentVersion: currentVersion,
          );
        }

        return UpdateCheckResult(
          status: UpdateStatus.softUpdate,
          config: config,
          currentVersion: currentVersion,
        );
      }

      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        config: config,
        currentVersion: currentVersion,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return UpdateCheckResult(
        status: UpdateStatus.unknown,
        error: e.toString(),
      );
    }
  }

  /// Downloads the APK from the given URL.
  ///
  /// Reports progress via the [onProgress] callback (0.0 to 1.0).
  /// Returns the downloaded [File] when complete.
  ///
  /// If the file already exists and is non-empty, returns it immediately
  /// (assumes it's a valid cached download).
  ///
  /// [url] The direct download URL for the APK.
  /// [version] Version string used for the filename.
  /// [onProgress] Callback invoked with download progress (0.0 to 1.0).
  ///
  /// Throws [Exception] if download fails.
  Future<File> downloadApk(
    String url,
    String version, {
    required Function(double) onProgress,
  }) async {
    final client = http.Client();
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'unfilter_update_$version.apk';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);

      // Check if file already exists and is valid
      if (await file.exists() && await file.length() > 0) {
        onProgress(1.0);
        return file;
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      final contentLength = response.contentLength ?? 0;

      // Create a temporary file to avoid partial downloads with final name
      final String tempFilePath = '${tempDir.path}/$fileName.tmp';
      final File tempFile = File(tempFilePath);

      // Clean up old temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      double received = 0;
      final IOSink sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      // Rename tmp to final
      await tempFile.rename(filePath);

      return File(filePath);
    } catch (e) {
      throw Exception('Download failed: $e');
    } finally {
      client.close();
    }
  }

  /// Triggers installation of the downloaded APK.
  ///
  /// Opens the APK file using the system's package installer.
  /// Note: The actual installation is handled by Android's package manager.
  ///
  /// [file] The APK file to install.
  ///
  /// Throws [Exception] if the file doesn't exist.
  Future<void> installApk(File file) async {
    if (!await file.exists()) {
      throw Exception('APK file not found');
    }

    debugPrint('Installing APK: ${file.path}');
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      debugPrint('OpenFilex result: ${result.type} - ${result.message}');
    }
  }

  /// Compares versions respecting build number if main version is equal.
  ///
  /// The pub_semver package treats build numbers as ignored for precedence.
  /// This method provides precise control by checking build numbers
  /// when the semantic version parts are equal.
  bool _isLowerThan(Version current, Version target) {
    if (current < target) return true;
    if (current > target) return false;

    // If SemVer equal, check build
    if (current == target) {
      final currentBuild = _parseBuildNumber(current.build);
      final targetBuild = _parseBuildNumber(target.build);
      if (currentBuild != null && targetBuild != null) {
        return currentBuild < targetBuild;
      }
    }
    return false;
  }

  /// Parses the build number from the version's build list.
  ///
  /// Returns null if no valid build number is found.
  int? _parseBuildNumber(List<dynamic> build) {
    if (build.isEmpty) return null;
    final first = build.first;
    if (first is int) return first;
    if (first is String) return int.tryParse(first);
    return null;
  }
}
