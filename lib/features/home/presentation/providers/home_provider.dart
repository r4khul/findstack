import 'package:findstack/features/apps/data/repositories/device_apps_repository.dart';
import 'package:findstack/features/apps/domain/entities/device_app.dart';
import 'package:findstack/features/scan/domain/entities/scan_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

final categoryFilterProvider = StateProvider<AppCategory?>((ref) => null);
final searchFilterProvider = StateProvider<String>((ref) => '');

final filteredAppsProvider = Provider<List<DeviceApp>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  final query = ref.watch(searchFilterProvider).toLowerCase();
  final category = ref.watch(categoryFilterProvider);

  return appsAsync.maybeWhen(
    data: (apps) {
      return apps.where((app) {
        final matchesQuery =
            app.appName.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
        final matchesCategory = category == null || app.category == category;
        return matchesQuery && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});
