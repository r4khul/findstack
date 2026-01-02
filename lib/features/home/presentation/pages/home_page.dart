import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_apps_repository.dart';
import '../providers/home_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/scan_progress_widget.dart';
import '../pages/search_page.dart';
import '../../domain/device_app.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final usagePermissionAsync = ref.watch(usagePermissionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("FindStack"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Scanning",
            onPressed: () => ref.refresh(installedAppsProvider),
          ),
        ],
      ),
      body: appsAsync.when(
        data: (apps) {
          final category = ref.watch(categoryFilterProvider);
          final filteredApps = apps.where((app) {
            return category == null || app.category == category;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      usagePermissionAsync.when(
                        data: (hasPermission) {
                          if (!hasPermission) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.security, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Grant Usage Access to see time stats.",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(deviceAppsRepositoryProvider)
                                          .requestUsagePermission()
                                          .then((_) {
                                            // Wait a bit for user to come back
                                            Future.delayed(
                                              const Duration(seconds: 2),
                                              () {
                                                ref.refresh(
                                                  usagePermissionProvider,
                                                );
                                                ref.refresh(
                                                  installedAppsProvider,
                                                );
                                              },
                                            );
                                          });
                                    },
                                    child: const Text("GRANT"),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                      ),
                      Text(
                        "Your Digital Life",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        "${apps.length} Installed Apps",
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SearchPage(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    const begin = Offset(0.0, 0.1);
                                    const end = Offset.zero;
                                    const curve = Curves.easeOutCubic;
                                    var tween = Tween(
                                      begin: begin,
                                      end: end,
                                    ).chain(CurveTween(curve: curve));
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      ),
                                    );
                                  },
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Search installed apps...",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                              isSelected:
                                  ref.watch(categoryFilterProvider) == null,
                            ),
                            ...AppCategory.values
                                .where((c) => c != AppCategory.unknown)
                                .map((cat) {
                                  return _buildCategoryChip(
                                    context,
                                    ref,
                                    label: cat.name.toUpperCase(),
                                    category: cat,
                                    isSelected:
                                        ref.watch(categoryFilterProvider) ==
                                        cat,
                                  );
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AppCard(app: filteredApps[index]),
                  childCount: filteredApps.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => Consumer(
          builder: (context, ref, _) {
            final progressAsync = ref.watch(scanProgressProvider);
            return progressAsync.when(
              data: (progress) => ScanProgressWidget(progress: progress),
              // If stream hasn't emitted yet, show indefinite spinner
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
            );
          },
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Something went wrong while scanning.\n$err",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
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
