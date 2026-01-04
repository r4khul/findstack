class SystemDetails {
  final Map<String, int> memInfo;
  final double cpuTemp;
  final String gpuUsage;
  final String kernel;

  const SystemDetails({
    required this.memInfo,
    required this.cpuTemp,
    required this.gpuUsage,
    required this.kernel,
  });

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

  // Helpers for memInfo (Values in kB usually)
  int get memTotalkb => memInfo['MemTotal'] ?? 0;
  int get memFreeKb => memInfo['MemFree'] ?? 0;
  int get memAvailableKb => memInfo['MemAvailable'] ?? 0;
  int get cachedKb => memInfo['Cached'] ?? 0;
  int get buffersKb => memInfo['Buffers'] ?? 0;
  int get swapTotalKb => memInfo['SwapTotal'] ?? 0;
  int get swapFreeKb => memInfo['SwapFree'] ?? 0;

  // Derived
  int get memUsedKb => memTotalkb - memAvailableKb; // Roughly
  int get cachedRealKb => cachedKb + buffersKb;
}
