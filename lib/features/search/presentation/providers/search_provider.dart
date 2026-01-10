import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import 'tech_stack_provider.dart';

class CategoryFilterNotifier extends Notifier<AppCategory?> {
  @override
  AppCategory? build() => null;

  void setCategory(AppCategory? category) {
    state = category;
  }
}

class SearchFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, AppCategory?>(
      CategoryFilterNotifier.new,
    );

final searchFilterProvider = NotifierProvider<SearchFilterNotifier, String>(
  SearchFilterNotifier.new,
);

final filteredAppsProvider = Provider<List<DeviceApp>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  final query = ref.watch(searchFilterProvider).toLowerCase();
  final category = ref.watch(categoryFilterProvider);
  final techStack = ref.watch(techStackFilterProvider);

  return appsAsync.maybeWhen(
    data: (apps) {
      return apps.where((app) {
        final matchesQuery =
            app.appName.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
        final matchesCategory = category == null || app.category == category;

        bool matchesStack = true;
        if (techStack != null && techStack != 'All') {
          // "Android" is strict mismatch if the stack is different?
          // Or does "Android" native map to Java/Kotlin?
          // For now, let's assume strict string match on the stack field we have on DeviceApp
          // But wait, DeviceApp.stack might be 'Native (Kotlin)' or just 'Kotlin'.
          // Let's assume the detector returns simple strings like 'Flutter', 'React Native'.
          if (techStack == 'Android') {
            // Match Native Default
            matchesStack = ['Java', 'Kotlin', 'Android'].contains(app.stack);
          } else {
            matchesStack = app.stack.toLowerCase() == techStack.toLowerCase();
          }
        }

        return matchesQuery && matchesCategory && matchesStack;
      }).toList();
    },
    orElse: () => [],
  );
});
