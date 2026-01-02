import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

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
