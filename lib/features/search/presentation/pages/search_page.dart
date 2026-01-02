import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../providers/search_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apps = ref.watch(filteredAppsProvider);
    final searchQuery = ref.watch(searchFilterProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: "Search apps, packages...",
                            border: InputBorder.none,
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.hintColor.withOpacity(0.5),
                            ),
                          ),
                          style: theme.textTheme.bodyLarge,
                          onChanged: (val) =>
                              ref.read(searchFilterProvider.notifier).state =
                                  val,
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ref.read(searchFilterProvider.notifier).state = '';
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Slider
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          context,
                          ref,
                          label: "All Apps",
                          category: null,
                          isSelected: selectedCategory == null,
                        ),
                        ...AppCategory.values
                            .where((c) => c != AppCategory.unknown)
                            .map((cat) {
                              return _buildCategoryChip(
                                context,
                                ref,
                                label: cat.name.toUpperCase(),
                                category: cat,
                                isSelected: selectedCategory == cat,
                              );
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: apps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No apps found",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 32),
                      itemCount: apps.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AppCard(app: apps[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required AppCategory? category,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(categoryFilterProvider.notifier).state = category;
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
