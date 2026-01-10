/// Data model representing the remote update configuration.
///
/// This model is fetched from a remote JSON endpoint and contains
/// all information needed to determine if an update is available
/// and what the update contains.
library;

import 'package:pub_semver/pub_semver.dart';

/// Configuration model for app updates.
///
/// Contains version information, download URLs, and release notes
/// used to determine update availability and display update UI.
///
/// ## JSON Structure
/// The expected JSON structure is:
/// ```json
/// {
///   "latest_native_version": "1.2.0+42",
///   "min_supported_native_version": "1.0.0+1",
///   "release_page_url": "https://...",
///   "apk_direct_download_url": "https://...",
///   "release_notes": "Optional release notes",
///   "force_update": false,
///   "features": ["Feature 1", "Feature 2"],
///   "fixes": ["Bug fix 1", "Bug fix 2"]
/// }
/// ```
class UpdateConfigModel {
  /// The latest available native version.
  ///
  /// Users with versions lower than this will see an update prompt.
  final Version latestNativeVersion;

  /// The minimum supported native version.
  ///
  /// Users with versions lower than this will be forced to update
  /// (cannot use the app until they update).
  final Version minSupportedNativeVersion;

  /// URL to the release page (e.g., GitHub releases).
  ///
  /// Used for users who want to manually download or view more details.
  final String releasePageUrl;

  /// Direct download URL for the APK file.
  ///
  /// This URL should point directly to the APK binary for
  /// the in-app download feature.
  final String apkDirectDownloadUrl;

  /// Optional release notes text.
  ///
  /// A brief overview of what's new in this release.
  final String? releaseNotes;

  /// Whether to force the update regardless of version.
  ///
  /// When true, even soft updates become force updates.
  /// Use sparingly for critical fixes.
  final bool forceUpdate;

  /// List of new features in this release.
  ///
  /// Displayed in the changelog section of the update UI.
  final List<String> features;

  /// List of bug fixes in this release.
  ///
  /// Displayed in the changelog section of the update UI.
  final List<String> fixes;

  /// Creates an update configuration model.
  const UpdateConfigModel({
    required this.latestNativeVersion,
    required this.minSupportedNativeVersion,
    required this.releasePageUrl,
    required this.apkDirectDownloadUrl,
    this.releaseNotes,
    required this.forceUpdate,
    this.features = const [],
    this.fixes = const [],
  });

  /// Whether there are any features or fixes to display.
  ///
  /// Returns true if either [features] or [fixes] has items.
  bool get hasChangelog => features.isNotEmpty || fixes.isNotEmpty;

  /// Total number of changes (features + fixes).
  int get totalChanges => features.length + fixes.length;

  /// Creates an [UpdateConfigModel] from a JSON map.
  ///
  /// Throws [FormatException] if the JSON is malformed or
  /// required fields are missing.
  ///
  /// [json] The decoded JSON map from the remote config.
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
        features:
            (json['features'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        fixes:
            (json['fixes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
    } catch (e) {
      throw FormatException('Failed to parse UpdateConfigModel: $e');
    }
  }

  /// Converts this model to a JSON map.
  ///
  /// Useful for caching the config locally.
  Map<String, dynamic> toJson() {
    return {
      'latest_native_version': latestNativeVersion.toString(),
      'min_supported_native_version': minSupportedNativeVersion.toString(),
      'release_page_url': releasePageUrl,
      'apk_direct_download_url': apkDirectDownloadUrl,
      'release_notes': releaseNotes,
      'force_update': forceUpdate,
      'features': features,
      'fixes': fixes,
    };
  }
}
