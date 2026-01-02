import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_apps_repository.dart';
import '../../domain/device_app.dart';
import '../../domain/scan_progress.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

final installedAppsProvider = FutureProvider<List<DeviceApp>>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.getInstalledApps();
});

final scanProgressProvider = StreamProvider<ScanProgress>((ref) {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return repository.scanProgressStream;
});

final usagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.checkUsagePermission();
});
