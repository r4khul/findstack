class ScanProgress {
  final String status;
  final int percent;
  final int processedCount;
  final int totalCount;

  ScanProgress({
    required this.status,
    required this.percent,
    required this.processedCount,
    required this.totalCount,
  });

  factory ScanProgress.fromMap(Map<dynamic, dynamic> map) {
    return ScanProgress(
      status: map['status'] as String? ?? '',
      percent: map['percent'] as int? ?? 0,
      processedCount: map['current'] as int? ?? 0,
      totalCount: map['total'] as int? ?? 0,
    );
  }
}
