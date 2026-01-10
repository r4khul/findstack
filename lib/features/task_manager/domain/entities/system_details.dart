/// Data model for system-level device information.
///
/// This entity captures detailed system metrics from the device,
/// including memory info from /proc/meminfo, CPU temperature, GPU usage,
/// and kernel version.
library;

/// Represents system-level details from the Android device.
///
/// This data is typically obtained from native code reading system files
/// like `/proc/meminfo`, `/sys/class/thermal`, and other system information.
///
/// ## Fields
/// - [memInfo]: Map of memory metrics from /proc/meminfo
/// - [cpuTemp]: Current CPU temperature in Celsius
/// - [gpuUsage]: GPU usage string (may be "N/A" on some devices)
/// - [kernel]: Kernel version string
///
/// ## Example
/// ```dart
/// final details = SystemDetails(
///   memInfo: {'MemTotal': 8192000, 'MemFree': 2048000},
///   cpuTemp: 42.5,
///   gpuUsage: "25%",
///   kernel: "5.4.0-android",
/// );
/// ```
class SystemDetails {
  /// Raw memory information from /proc/meminfo.
  ///
  /// Keys typically include: MemTotal, MemFree, MemAvailable,
  /// Cached, Buffers, SwapTotal, SwapFree.
  /// Values are in kilobytes.
  final Map<String, int> memInfo;

  /// CPU temperature in degrees Celsius.
  ///
  /// May be 0.0 if thermal information is unavailable.
  final double cpuTemp;

  /// GPU usage string.
  ///
  /// Format varies by device. Returns "N/A" if unavailable.
  final String gpuUsage;

  /// Linux kernel version string.
  final String kernel;

  /// Creates a system details instance.
  const SystemDetails({
    required this.memInfo,
    required this.cpuTemp,
    required this.gpuUsage,
    required this.kernel,
  });

  /// Creates a [SystemDetails] from a native Map.
  ///
  /// Used when parsing data received from native Android code
  /// through platform channels.
  factory SystemDetails.fromMap(Map<Object?, Object?> map) {
    final rawMem = map['memInfo'];
    Map<String, int> memMap = {};
    if (rawMem is Map) {
      rawMem.forEach((key, value) {
        if (key is String && value is int) {
          memMap[key] = value;
        } else if (key is String && value is String) {
          memMap[key] = int.tryParse(value) ?? 0;
        }
      });
    }

    return SystemDetails(
      memInfo: memMap,
      cpuTemp: (map['cpuTemp'] as num?)?.toDouble() ?? 0.0,
      gpuUsage: map['gpuUsage']?.toString() ?? "N/A",
      kernel: map['kernel']?.toString() ?? "Unknown",
    );
  }

  // ===========================================================================
  // MEMORY HELPERS
  // ===========================================================================
  // Values are in kilobytes

  /// Total physical memory in KB.
  int get memTotalkb => memInfo['MemTotal'] ?? 0;

  /// Free memory in KB (not including cached).
  int get memFreeKb => memInfo['MemFree'] ?? 0;

  /// Available memory in KB (including reclaimable cache).
  int get memAvailableKb => memInfo['MemAvailable'] ?? 0;

  /// Page cache in KB.
  int get cachedKb => memInfo['Cached'] ?? 0;

  /// Buffer cache in KB.
  int get buffersKb => memInfo['Buffers'] ?? 0;

  /// Total swap space in KB.
  int get swapTotalKb => memInfo['SwapTotal'] ?? 0;

  /// Free swap space in KB.
  int get swapFreeKb => memInfo['SwapFree'] ?? 0;

  // ===========================================================================
  // DERIVED METRICS
  // ===========================================================================

  /// Used memory in KB (total - available).
  ///
  /// This is an approximation of actually used memory.
  int get memUsedKb => memTotalkb - memAvailableKb;

  /// Total cached/buffered memory in KB.
  ///
  /// This memory can be reclaimed by the system when needed.
  int get cachedRealKb => cachedKb + buffersKb;
}
