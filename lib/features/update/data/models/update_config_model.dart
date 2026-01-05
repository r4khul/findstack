import 'package:pub_semver/pub_semver.dart';

class UpdateConfigModel {
  final Version latestNativeVersion;
  final Version minSupportedNativeVersion;
  final String releasePageUrl;
  final String apkDirectDownloadUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  const UpdateConfigModel({
    required this.latestNativeVersion,
    required this.minSupportedNativeVersion,
    required this.releasePageUrl,
    required this.apkDirectDownloadUrl,
    this.releaseNotes,
    required this.forceUpdate,
  });

  factory UpdateConfigModel.fromJson(Map<String, dynamic> json) {
    try {
      return UpdateConfigModel(
        latestNativeVersion: Version.parse(
          json['latest_native_version'] as String,
        ),
        minSupportedNativeVersion: Version.parse(
          json['min_supported_native_version'] as String,
        ),
        releasePageUrl: json['release_page_url'] as String,
        apkDirectDownloadUrl: json['apk_direct_download_url'] as String,
        releaseNotes: json['release_notes'] as String?,
        forceUpdate: json['force_update'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Failed to parse UpdateConfigModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_native_version': latestNativeVersion.toString(),
      'min_supported_native_version': minSupportedNativeVersion.toString(),
      'release_page_url': releasePageUrl,
      'apk_direct_download_url': apkDirectDownloadUrl,
      'release_notes': releaseNotes,
      'force_update': forceUpdate,
    };
  }
}
