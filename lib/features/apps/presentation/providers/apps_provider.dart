import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/device_apps_repository.dart';
import '../../domain/entities/device_app.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

final installedAppsProvider = FutureProvider<List<DeviceApp>>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.getInstalledApps();
});

final usagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.checkUsagePermission();
});
