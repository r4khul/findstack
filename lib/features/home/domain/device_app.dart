class DeviceApp {
  final String appName;
  final String packageName;
  final String version;
  final String stack;
  final List<String> nativeLibraries;
  final bool isSystem;

  DeviceApp({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.stack,
    required this.nativeLibraries,
    required this.isSystem,
  });

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    return DeviceApp(
      appName: map['appName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      version: map['version'] as String? ?? '',
      stack: map['stack'] as String? ?? 'Unknown',
      nativeLibraries:
          (map['nativeLibraries'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isSystem: map['isSystem'] as bool? ?? false,
    );
  }
}
