import 'package:flutter/foundation.dart';

/// Configuration model for customizable share poster options.
/// Uses value semantics for efficient comparison and immutability.
@immutable
class ShareOptionsConfig {
  final bool showVersion;
  final bool showSdk;
  final bool showUsage;
  final bool showInstallDate;
  final bool showSize;
  final bool showSource;
  final bool showTechVersions;
  final bool showComponents;
  final bool showSplitApks;

  const ShareOptionsConfig({
    this.showVersion = true,
    this.showSdk = true,
    this.showUsage = true,
    this.showInstallDate = true,
    this.showSize = true,
    this.showSource = true,
    this.showTechVersions = true,
    this.showComponents = true,
    this.showSplitApks = true,
  });

  /// Creates a copy with the specified field toggled
  ShareOptionsConfig copyWith({
    bool? showVersion,
    bool? showSdk,
    bool? showUsage,
    bool? showInstallDate,
    bool? showSize,
    bool? showSource,
    bool? showTechVersions,
    bool? showComponents,
    bool? showSplitApks,
  }) {
    return ShareOptionsConfig(
      showVersion: showVersion ?? this.showVersion,
      showSdk: showSdk ?? this.showSdk,
      showUsage: showUsage ?? this.showUsage,
      showInstallDate: showInstallDate ?? this.showInstallDate,
      showSize: showSize ?? this.showSize,
      showSource: showSource ?? this.showSource,
      showTechVersions: showTechVersions ?? this.showTechVersions,
      showComponents: showComponents ?? this.showComponents,
      showSplitApks: showSplitApks ?? this.showSplitApks,
    );
  }

  /// Count of enabled options for UI feedback
  int get enabledCount {
    int count = 0;
    if (showVersion) count++;
    if (showSdk) count++;
    if (showUsage) count++;
    if (showInstallDate) count++;
    if (showSize) count++;
    if (showSource) count++;
    if (showTechVersions) count++;
    if (showComponents) count++;
    if (showSplitApks) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareOptionsConfig &&
          runtimeType == other.runtimeType &&
          showVersion == other.showVersion &&
          showSdk == other.showSdk &&
          showUsage == other.showUsage &&
          showInstallDate == other.showInstallDate &&
          showSize == other.showSize &&
          showSource == other.showSource &&
          showTechVersions == other.showTechVersions &&
          showComponents == other.showComponents &&
          showSplitApks == other.showSplitApks;

  @override
  int get hashCode => Object.hash(
    showVersion,
    showSdk,
    showUsage,
    showInstallDate,
    showSize,
    showSource,
    showTechVersions,
    showComponents,
    showSplitApks,
  );
}
