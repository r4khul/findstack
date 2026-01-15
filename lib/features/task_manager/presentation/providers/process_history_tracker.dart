library;

import 'package:flutter/foundation.dart';

import '../../domain/entities/android_process.dart';
import '../../domain/entities/process_snapshot.dart';
import '../../domain/entities/process_with_history.dart';

/// Tracks process history across multiple refresh cycles.
/// Maintains a map of PID -> ProcessHistory.
class ProcessHistoryTracker {
  final Map<String, ProcessHistory> _historyMap = {};

  /// Update with new process data, returns processes enriched with history
  List<ProcessWithHistory> updateWithProcesses(List<AndroidProcess> processes) {
    final currentPids = <String>{};
    final result = <ProcessWithHistory>[];

    // Debug: count active CPU processes
    int activeCount = 0;
    double maxCpu = 0;

    for (final process in processes) {
      currentPids.add(process.pid);

      // Get or create history for this PID
      var history = _historyMap[process.pid];
      if (history == null) {
        history = ProcessHistory(pid: process.pid);
        _historyMap[process.pid] = history;
      }

      // Parse CPU value
      final cpuValue = double.tryParse(process.cpu) ?? 0;

      if (cpuValue > 0) {
        activeCount++;
        if (cpuValue > maxCpu) maxCpu = cpuValue;
      }

      // Add new snapshot
      history.addSnapshot(
        ProcessSnapshot.fromProcess(
          cpu: cpuValue,
          memory: _parseMemoryPercentage(process.res),
        ),
      );

      // Create enriched process
      result.add(ProcessWithHistory.fromHistory(process, history));
    }

    // Debug log
    if (result.isNotEmpty) {
      debugPrint(
        '[HistoryTracker] Processes: ${result.length}, Active (CPU>0): $activeCount, Max CPU: $maxCpu',
      );
    }

    // Clean up dead processes (not seen in last 3 refreshes worth of time)
    _cleanupStaleProcesses(currentPids);

    return result;
  }

  /// Parse memory string (e.g., "125M", "2.5G") to percentage (rough estimate)
  double _parseMemoryPercentage(String memString) {
    try {
      final normalized = memString.toUpperCase().trim();
      double value = 0;

      if (normalized.endsWith('G')) {
        value = double.parse(normalized.replaceAll('G', '')) * 1024;
      } else if (normalized.endsWith('M')) {
        value = double.parse(normalized.replaceAll('M', ''));
      } else if (normalized.endsWith('K')) {
        value = double.parse(normalized.replaceAll('K', '')) / 1024;
      } else {
        value = double.tryParse(normalized) ?? 0;
      }

      // Rough percentage (assuming 8GB total RAM as baseline)
      const totalRamMb = 8 * 1024;
      return (value / totalRamMb * 100).clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  /// Remove processes that haven't been seen recently
  void _cleanupStaleProcesses(Set<String> currentPids) {
    final staleThreshold = DateTime.now().subtract(const Duration(seconds: 30));
    final toRemove = <String>[];

    for (final entry in _historyMap.entries) {
      if (!currentPids.contains(entry.key)) {
        final lastSnapshot = entry.value.snapshots.lastOrNull;
        if (lastSnapshot == null ||
            lastSnapshot.timestamp.isBefore(staleThreshold)) {
          toRemove.add(entry.key);
        }
      }
    }

    for (final pid in toRemove) {
      _historyMap.remove(pid);
    }
  }

  /// Clear all history
  void reset() {
    _historyMap.clear();
  }

  /// Get history for a specific PID
  ProcessHistory? getHistory(String pid) => _historyMap[pid];
}
