library;

import 'dart:typed_data';

/// Lightweight app info for Task Manager's active apps section.
/// This is independent of the full DeviceApp model used in app scanning.
class ActiveApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int lastTimeUsed;
  final int totalTimeInForeground;

  const ActiveApp({
    required this.packageName,
    required this.appName,
    this.icon,
    required this.lastTimeUsed,
    this.totalTimeInForeground = 0,
  });

  factory ActiveApp.fromMap(Map<Object?, Object?> map) {
    Uint8List? iconBytes;
    final rawIcon = map['icon'];
    if (rawIcon is List) {
      iconBytes = Uint8List.fromList(rawIcon.cast<int>());
    }

    return ActiveApp(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? 'Unknown',
      icon: iconBytes,
      lastTimeUsed: (map['lastTimeUsed'] as num?)?.toInt() ?? 0,
      totalTimeInForeground:
          (map['totalTimeInForeground'] as num?)?.toInt() ?? 0,
    );
  }

  String get timeAgo {
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);

    if (diff.inSeconds < 60) {
      return "Active now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }

  bool get isRecentlyActive =>
      DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastTimeUsed))
          .inMinutes <
      5;

  String get formattedUsageTime {
    final minutes = totalTimeInForeground ~/ 60000;
    if (minutes < 60) {
      return "${minutes}m";
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return "${hours}h ${remainingMinutes}m";
  }
}
