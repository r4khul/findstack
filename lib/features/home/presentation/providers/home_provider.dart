import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_apps_repository.dart';
import '../../domain/device_app.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

final installedAppsProvider = FutureProvider<List<DeviceApp>>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.getInstalledApps();
});
