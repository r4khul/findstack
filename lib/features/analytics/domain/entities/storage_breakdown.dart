import 'package:equatable/equatable.dart';

class StorageBreakdown extends Equatable {
  final String packageName;

  final int apkSize;

  final int codeSize;

  final int appDataInternal;

  final int cacheInternal;

  final int cacheExternal;

  final int obbSize;

  final int externalDataSize;

  final int mediaSize;

  final int databasesSize;

  final int logsSize;

  final int residualSize;

  final MediaBreakdown mediaBreakdown;

  final Map<String, int> databaseBreakdown;

  final int totalExact;

  final int totalEstimated;

  final int totalCombined;

  final DateTime scanTimestamp;

  final double confidenceLevel;

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

  int get totalCache => cacheInternal + cacheExternal;

  bool get isDetailed => totalEstimated > 0 || limitations.isNotEmpty;

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
