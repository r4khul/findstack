library;

/// A single point-in-time snapshot of a process's resource usage.
/// Used for building history buffers for sparkline visualizations.
class ProcessSnapshot {
  final double cpu;
  final double memory;
  final DateTime timestamp;

  const ProcessSnapshot({
    required this.cpu,
    required this.memory,
    required this.timestamp,
  });

  factory ProcessSnapshot.fromProcess({
    required double cpu,
    required double memory,
  }) {
    return ProcessSnapshot(cpu: cpu, memory: memory, timestamp: DateTime.now());
  }
}

/// Maximum number of history points to keep (15 points × 2s = 30 seconds)
const int kMaxHistoryPoints = 15;

/// Maintains a circular buffer of process snapshots for a single process.
class ProcessHistory {
  final String pid;
  final List<ProcessSnapshot> _snapshots;

  ProcessHistory({required this.pid}) : _snapshots = [];

  List<ProcessSnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// CPU usage history as a list of values (0-100)
  List<double> get cpuHistory => _snapshots.map((s) => s.cpu).toList();

  /// Memory history as a list of percentages
  List<double> get memoryHistory => _snapshots.map((s) => s.memory).toList();

  /// Latest CPU value
  double get currentCpu => _snapshots.isEmpty ? 0 : _snapshots.last.cpu;

  /// Latest memory value
  double get currentMemory => _snapshots.isEmpty ? 0 : _snapshots.last.memory;

  /// Whether we have enough data for visualization (at least 2 points)
  bool get hasEnoughData => _snapshots.length >= 2;

  /// CPU trend: positive = rising, negative = falling, 0 = stable
  double get cpuTrend {
    if (_snapshots.length < 3) return 0;
    final recent = _snapshots.sublist(_snapshots.length - 3);
    final avg = recent.map((s) => s.cpu).reduce((a, b) => a + b) / 3;
    final oldest = recent.first.cpu;
    return avg - oldest;
  }

  /// Add a new snapshot, maintaining the circular buffer limit
  void addSnapshot(ProcessSnapshot snapshot) {
    _snapshots.add(snapshot);
    while (_snapshots.length > kMaxHistoryPoints) {
      _snapshots.removeAt(0);
    }
  }

  /// Clear all history
  void clear() => _snapshots.clear();
}
