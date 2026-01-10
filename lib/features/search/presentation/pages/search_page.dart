import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../../../apps/presentation/widgets/category_slider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/app_count_badge.dart';
import '../widgets/tech_stack_filter.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apps = ref.watch(filteredAppsProvider);
    final searchQuery = ref.watch(searchFilterProvider);

    return AppCountOverlay(
      count: apps.length,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Container(
            height: 50,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "Search apps...",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      fillColor: theme.colorScheme.surface,
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                    onChanged: (val) =>
                        ref.read(searchFilterProvider.notifier).setQuery(val),
                    controller: TextEditingController(text: searchQuery)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: searchQuery.length),
                      ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        ref.read(searchFilterProvider.notifier).clear(),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          actions: [const TechStackFilter(), const SizedBox(width: 20)],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const CategorySlider(
                  isCompact: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        body: apps.isEmpty
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: apps.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(app: apps[index]),
                ),
              ),
      ),
    );
  }
}
