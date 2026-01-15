library;

import 'android_process.dart';
import 'process_snapshot.dart';

/// An Android process combined with its historical usage data.
/// Used for rendering sparkline visualizations in the Task Manager.
class ProcessWithHistory {
  final AndroidProcess process;
  final List<double> cpuHistory;
  final List<double> memoryHistory;

  const ProcessWithHistory({
    required this.process,
    this.cpuHistory = const [],
    this.memoryHistory = const [],
  });

  /// Whether we have enough history for visualization
  bool get hasHistory => cpuHistory.length >= 2;

  /// Get current CPU as double
  double get currentCpu => double.tryParse(process.cpu) ?? 0;

  /// Calculate CPU trend: rising, falling, or stable
  ResourceTrend get cpuTrend {
    if (cpuHistory.length < 3) return ResourceTrend.stable;
    final recent = cpuHistory.sublist(cpuHistory.length - 3);
    final avg = recent.reduce((a, b) => a + b) / 3;
    final oldest = recent.first;
    final diff = avg - oldest;
    if (diff > 5) return ResourceTrend.rising;
    if (diff < -5) return ResourceTrend.falling;
    return ResourceTrend.stable;
  }

  /// Get intensity level for color coding (0-4)
  /// 0 = idle, 1 = low, 2 = moderate, 3 = high, 4 = critical
  int get intensityLevel {
    final cpu = currentCpu;
    if (cpu < 5) return 0;
    if (cpu < 15) return 1;
    if (cpu < 35) return 2;
    if (cpu < 60) return 3;
    return 4;
  }

  /// Whether this process should show a warning glow
  bool get shouldGlow => intensityLevel >= 3;

  /// Create from an AndroidProcess and ProcessHistory
  factory ProcessWithHistory.fromHistory(
    AndroidProcess process,
    ProcessHistory? history,
  ) {
    return ProcessWithHistory(
      process: process,
      cpuHistory: history?.cpuHistory ?? [],
      memoryHistory: history?.memoryHistory ?? [],
    );
  }
}

enum ResourceTrend { rising, stable, falling }
