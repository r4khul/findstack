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

enum UpdateStatus {
  upToDate,

  softUpdate,

  forceUpdate,

  unknown,
}

class UpdateCheckResult {
  final UpdateStatus status;

  final UpdateConfigModel? config;

  final Version? currentVersion;

  final String? error;

  final UpdateErrorType? errorType;

  const UpdateCheckResult({
    required this.status,
    this.config,
    this.currentVersion,
    this.error,
    this.errorType,
  });
}

class UpdateService {
  final UpdateRepository _repository;

  UpdateService(this._repository);

  Future<Version> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    String versionString = packageInfo.version;
    if (packageInfo.buildNumber.isNotEmpty) {
      versionString = '$versionString+${packageInfo.buildNumber}';
    }
    return Version.parse(versionString);
  }

  Future<UpdateCheckResult> checkUpdate() async {
    try {
      final config = await _repository.fetchConfig();
      if (config == null) {
        return const UpdateCheckResult(status: UpdateStatus.unknown);
      }

      final currentVersion = await getCurrentVersion();

      if (_isLowerThan(currentVersion, config.minSupportedNativeVersion)) {
        return UpdateCheckResult(
          status: UpdateStatus.forceUpdate,
          config: config,
          currentVersion: currentVersion,
        );
      }

      if (_isLowerThan(currentVersion, config.latestNativeVersion)) {
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

      if (await file.exists() && await file.length() > 0) {
        onProgress(1.0);
        return file;
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      final contentLength = response.contentLength ?? 0;

      final String tempFilePath = '${tempDir.path}/$fileName.tmp';
      final File tempFile = File(tempFilePath);

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

      await tempFile.rename(filePath);

      return File(filePath);
    } catch (e) {
      throw Exception('Download failed: $e');
    } finally {
      client.close();
    }
  }

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

  bool _isLowerThan(Version current, Version target) {
    if (current < target) return true;
    if (current > target) return false;

    if (current == target) {
      final currentBuild = _parseBuildNumber(current.build);
      final targetBuild = _parseBuildNumber(target.build);
      if (currentBuild != null && targetBuild != null) {
        return currentBuild < targetBuild;
      }
    }
    return false;
  }

  int? _parseBuildNumber(List<dynamic> build) {
    if (build.isEmpty) return null;
    final first = build.first;
    if (first is int) return first;
    if (first is String) return int.tryParse(first);
    return null;
  }
}
