import 'package:equatable/equatable.dart';

/// Represents a Semantic Version (x.y.z+build).
class AppVersion extends Equatable implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;
  final int? shorebirdPatch;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
    this.shorebirdPatch,
  });

  /// Parse from standard string "1.0.0+1"
  factory AppVersion.parse(String versionString) {
    try {
      final parts = versionString.split('+');
      final versionParts = parts[0].split('.');

      final major = int.parse(versionParts[0]);
      final minor = int.parse(versionParts[1]);
      final patch = int.parse(versionParts[2]);

      final build = parts.length > 1 ? int.parse(parts[1]) : 0;

      return AppVersion(major: major, minor: minor, patch: patch, build: build);
    } catch (e) {
      throw FormatException('Invalid version format: $versionString');
    }
  }

  AppVersion withShorebirdPatch(int? patchNumber) {
    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: build,
      shorebirdPatch: patchNumber,
    );
  }

  String get nativeVersion => '$major.$minor.$patch';
  String get fullVersion => '$major.$minor.$patch+$build';

  /// Returns the display version.
  /// If shorebird patch is present, we append it.
  /// User rule: "Build number +N = Shorebird patch number"
  /// We will format it as x.y.z+(Build+Patch) or x.y.z+Build (Patch N)
  /// for clarity and safety, showing both is better, but obeying strict rule:
  /// We can just render string as x.y.z+(build + (shorebirdPatch ?? 0))
  String get displayString {
    final effectiveBuild = build + (shorebirdPatch ?? 0);
    return '$major.$minor.$patch+$effectiveBuild';
  }

  bool isLowerThan(AppVersion other, {bool ignoreBuild = false}) {
    if (major < other.major) return true;
    if (major > other.major) return false;

    if (minor < other.minor) return true;
    if (minor > other.minor) return false;

    if (patch < other.patch) return true;
    if (patch > other.patch) return false;

    if (!ignoreBuild) {
      if (build < other.build) return true;
    }

    return false;
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  @override
  List<Object?> get props => [major, minor, patch, build, shorebirdPatch];

  @override
  String toString() => displayString;
}

enum AppUpdateStatus {
  upToDate,
  softUpdate, // Optional update available
  forceUpdate, // Mandatory update required
}

class UpdateConfig extends Equatable {
  final AppVersion latestNativeVersion;
  final AppVersion minSupportedNativeVersion;
  final String apkUrl;
  final String? releaseNotes;

  const UpdateConfig({
    required this.latestNativeVersion,
    required this.minSupportedNativeVersion,
    required this.apkUrl,
    this.releaseNotes,
  });

  factory UpdateConfig.fromJson(Map<String, dynamic> json) {
    return UpdateConfig(
      latestNativeVersion: AppVersion.parse(
        json['latest_native_version'] as String,
      ),
      minSupportedNativeVersion: AppVersion.parse(
        json['min_supported_native_version'] as String,
      ),
      apkUrl: json['apk_url'] as String,
      releaseNotes: json['release_notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    latestNativeVersion,
    minSupportedNativeVersion,
    apkUrl,
    releaseNotes,
  ];
}
