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
          if (techStack == 'Android') {
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
