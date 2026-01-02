class AppUsagePoint {
  final DateTime date;
  final Duration usage;

  AppUsagePoint({required this.date, required this.usage});

  factory AppUsagePoint.fromMap(Map<Object?, Object?> map) {
    return AppUsagePoint(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int? ?? 0),
      usage: Duration(milliseconds: map['usage'] as int? ?? 0),
    );
  }
}
