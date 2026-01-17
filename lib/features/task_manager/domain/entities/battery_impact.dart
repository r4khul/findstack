library;

import 'dart:typed_data';

/// Represents battery impact data for a single app.
class AppBatteryImpact {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int foregroundTimeMs;
  final int wakeupCount;
  final int foregroundTransitions;
  final double cpuDrain;
  final double wakelockDrain;
  final double networkDrain;
  final double totalDrain;
  final bool isBackgroundVampire;

  const AppBatteryImpact({
    required this.packageName,
    required this.appName,
    this.icon,
    required this.foregroundTimeMs,
    required this.wakeupCount,
    required this.foregroundTransitions,
    required this.cpuDrain,
    required this.wakelockDrain,
    required this.networkDrain,
    required this.totalDrain,
    required this.isBackgroundVampire,
  });

  factory AppBatteryImpact.fromMap(Map<Object?, Object?> map) {
    Uint8List? iconBytes;
    final rawIcon = map['icon'];
    if (rawIcon is List) {
      iconBytes = Uint8List.fromList(rawIcon.cast<int>());
    }

    return AppBatteryImpact(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? 'Unknown',
      icon: iconBytes,
      foregroundTimeMs: (map['foregroundTimeMs'] as num?)?.toInt() ?? 0,
      wakeupCount: (map['wakeupCount'] as num?)?.toInt() ?? 0,
      foregroundTransitions:
          (map['foregroundTransitions'] as num?)?.toInt() ?? 0,
      cpuDrain: (map['cpuDrain'] as num?)?.toDouble() ?? 0.0,
      wakelockDrain: (map['wakelockDrain'] as num?)?.toDouble() ?? 0.0,
      networkDrain: (map['networkDrain'] as num?)?.toDouble() ?? 0.0,
      totalDrain: (map['totalDrain'] as num?)?.toDouble() ?? 0.0,
      isBackgroundVampire: (map['isBackgroundVampire'] as bool?) ?? false,
    );
  }

  /// Returns formatted foreground time string.
  String get formattedForegroundTime {
    final minutes = foregroundTimeMs ~/ 60000;
    if (minutes < 60) {
      return "${minutes}m";
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours < 24) {
      return remainingMinutes > 0
          ? "${hours}h ${remainingMinutes}m"
          : "${hours}h";
    }
    return "${hours ~/ 24}d ${hours % 24}h";
  }

  /// Returns a human-readable drain description.
  String get drainDescription {
    if (totalDrain < 1) return "Minimal";
    if (totalDrain < 3) return "Low";
    if (totalDrain < 7) return "Moderate";
    if (totalDrain < 12) return "High";
    return "Very High";
  }

  /// Returns formatted total drain as percentage string.
  String get formattedDrain => "${totalDrain.toStringAsFixed(1)}%";

  /// Breakdown of drain sources for display.
  List<DrainBreakdownItem> get drainBreakdown => [
    DrainBreakdownItem(label: "CPU", value: cpuDrain, icon: "⚡"),
    DrainBreakdownItem(label: "Wakelock", value: wakelockDrain, icon: "🔔"),
    DrainBreakdownItem(label: "Network", value: networkDrain, icon: "📶"),
  ];
}

/// A single item in the drain breakdown.
class DrainBreakdownItem {
  final String label;
  final double value;
  final String icon;

  const DrainBreakdownItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  String get formatted => "${value.toStringAsFixed(1)}%";
}

/// Represents a single day's battery history for an app.
class DailyBatteryUsage {
  final DateTime date;
  final int foregroundTimeMs;
  final double estimatedDrain;

  const DailyBatteryUsage({
    required this.date,
    required this.foregroundTimeMs,
    required this.estimatedDrain,
  });

  factory DailyBatteryUsage.fromMap(Map<Object?, Object?> map) {
    final dateMs = (map['date'] as num?)?.toInt() ?? 0;
    return DailyBatteryUsage(
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      foregroundTimeMs: (map['foregroundTimeMs'] as num?)?.toInt() ?? 0,
      estimatedDrain: (map['estimatedDrain'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get formattedForegroundTime {
    final minutes = foregroundTimeMs ~/ 60000;
    if (minutes < 60) return "${minutes}m";
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0
        ? "${hours}h ${remainingMinutes}m"
        : "${hours}h";
  }
}

/// Aggregated battery impact data.
class BatteryImpactData {
  final List<AppBatteryImpact> apps;
  final List<AppBatteryImpact> vampires;
  final DateTime lastUpdated;

  const BatteryImpactData({
    required this.apps,
    required this.vampires,
    required this.lastUpdated,
  });

  /// Total estimated drain from all tracked apps.
  double get totalTrackedDrain =>
      apps.fold(0.0, (sum, app) => sum + app.totalDrain);

  /// Top 5 battery draining apps.
  List<AppBatteryImpact> get topDrainers => apps.take(5).toList();
}
