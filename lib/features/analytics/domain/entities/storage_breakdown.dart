import 'package:equatable/equatable.dart';

/// Comprehensive storage breakdown for an application.
/// Provides granular insight into where storage is consumed.
class StorageBreakdown extends Equatable {
  /// Package name this breakdown belongs to
  final String packageName;

  // ===== EXACT MEASUREMENTS (from StorageStatsManager) =====

  /// APK file size + split APKs
  final int apkSize;

  /// Code size (DEX, native libs inside APK)
  final int codeSize;

  /// Internal app data (databases, shared_prefs, etc.)
  final int appDataInternal;

  /// Internal cache directory
  final int cacheInternal;

  /// External cache directory
  final int cacheExternal;

  // ===== DISCOVERABLE (via file analysis) =====

  /// OBB files size (Android/obb/{package})
  final int obbSize;

  /// External app data (Android/data/{package})
  final int externalDataSize;

  /// Media files owned/created by app
  final int mediaSize;

  /// Database files total size
  final int databasesSize;

  /// Log files (.log, .txt logs)
  final int logsSize;

  /// Other discoverable files not categorized
  final int residualSize;

  // ===== DETAILED BREAKDOWNS =====

  /// Media breakdown by type
  final MediaBreakdown mediaBreakdown;

  /// Individual database files
  final Map<String, int> databaseBreakdown;

  // ===== METADATA =====

  /// Sum of exact measurements from official APIs
  final int totalExact;

  /// Sum of estimated/discovered measurements
  final int totalEstimated;

  /// Grand total (exact + estimated)
  final int totalCombined;

  /// When this breakdown was computed
  final DateTime scanTimestamp;

  /// Confidence level (0.0 - 1.0)
  final double confidenceLevel;

  /// List of limitations encountered during analysis
  final List<String> limitations;

  const StorageBreakdown({
    required this.packageName,
    this.apkSize = 0,
    this.codeSize = 0,
    this.appDataInternal = 0,
    this.cacheInternal = 0,
    this.cacheExternal = 0,
    this.obbSize = 0,
    this.externalDataSize = 0,
    this.mediaSize = 0,
    this.databasesSize = 0,
    this.logsSize = 0,
    this.residualSize = 0,
    this.mediaBreakdown = const MediaBreakdown(),
    this.databaseBreakdown = const {},
    this.totalExact = 0,
    this.totalEstimated = 0,
    this.totalCombined = 0,
    required this.scanTimestamp,
    this.confidenceLevel = 0.0,
    this.limitations = const [],
  });

  factory StorageBreakdown.fromMap(Map<Object?, Object?> map) {
    final mediaBreakdownMap = map['mediaBreakdown'] as Map<Object?, Object?>?;
    final dbBreakdownMap = map['databaseBreakdown'] as Map<Object?, Object?>?;

    return StorageBreakdown(
      packageName: map['packageName'] as String? ?? '',
      apkSize: map['apkSize'] as int? ?? 0,
      codeSize: map['codeSize'] as int? ?? 0,
      appDataInternal: map['appDataInternal'] as int? ?? 0,
      cacheInternal: map['cacheInternal'] as int? ?? 0,
      cacheExternal: map['cacheExternal'] as int? ?? 0,
      obbSize: map['obbSize'] as int? ?? 0,
      externalDataSize: map['externalDataSize'] as int? ?? 0,
      mediaSize: map['mediaSize'] as int? ?? 0,
      databasesSize: map['databasesSize'] as int? ?? 0,
      logsSize: map['logsSize'] as int? ?? 0,
      residualSize: map['residualSize'] as int? ?? 0,
      mediaBreakdown: mediaBreakdownMap != null
          ? MediaBreakdown.fromMap(mediaBreakdownMap)
          : const MediaBreakdown(),
      databaseBreakdown:
          dbBreakdownMap?.map(
            (key, value) => MapEntry(key.toString(), value as int),
          ) ??
          {},
      totalExact: map['totalExact'] as int? ?? 0,
      totalEstimated: map['totalEstimated'] as int? ?? 0,
      totalCombined: map['totalCombined'] as int? ?? 0,
      scanTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['scanTimestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      confidenceLevel: (map['confidenceLevel'] as num?)?.toDouble() ?? 0.0,
      limitations:
          (map['limitations'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Get total cache size
  int get totalCache => cacheInternal + cacheExternal;

  /// Check if this is a detailed scan
  bool get isDetailed => totalEstimated > 0 || limitations.isNotEmpty;

  /// Check if scan is recent (within 5 minutes)
  bool get isRecent {
    final age = DateTime.now().difference(scanTimestamp);
    return age.inMinutes < 5;
  }

  @override
  List<Object?> get props => [
    packageName,
    apkSize,
    codeSize,
    appDataInternal,
    cacheInternal,
    cacheExternal,
    obbSize,
    externalDataSize,
    mediaSize,
    databasesSize,
    logsSize,
    residualSize,
    mediaBreakdown,
    databaseBreakdown,
    totalExact,
    totalEstimated,
    totalCombined,
    scanTimestamp,
    confidenceLevel,
    limitations,
  ];
}

/// Media storage breakdown by type
class MediaBreakdown extends Equatable {
  final int images;
  final int videos;
  final int audio;
  final int documents;

  const MediaBreakdown({
    this.images = 0,
    this.videos = 0,
    this.audio = 0,
    this.documents = 0,
  });

  factory MediaBreakdown.fromMap(Map<Object?, Object?> map) {
    return MediaBreakdown(
      images: map['images'] as int? ?? 0,
      videos: map['videos'] as int? ?? 0,
      audio: map['audio'] as int? ?? 0,
      documents: map['documents'] as int? ?? 0,
    );
  }

  int get total => images + videos + audio + documents;

  @override
  List<Object?> get props => [images, videos, audio, documents];
}
