import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/category_slider.dart';
import '../../../apps/presentation/widgets/apps_list_skeleton.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../search/presentation/widgets/tech_stack_filter.dart';
import '../../../search/presentation/providers/tech_stack_provider.dart';

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: appsAsync.when(
          data: (apps) {
            final category = ref.watch(categoryFilterProvider);
            final techStack = ref.watch(techStackFilterProvider);

            final filteredApps = apps.where((app) {
              final matchesCategory =
                  category == null || app.category == category;
              bool matchesStack = true;
              if (techStack != null && techStack != 'All') {
                if (techStack == 'Android') {
                  matchesStack = [
                    'Java',
                    'Kotlin',
                    'Android',
                  ].contains(app.stack);
                } else {
                  matchesStack =
                      app.stack.toLowerCase() == techStack.toLowerCase();
                }
              }
              return matchesCategory && matchesStack;
            }).toList();

            return CustomScrollView(
              key: const ValueKey('data'),
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
                          "Your Device has",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          "${apps.length} Installed Apps",
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const SearchPage(),
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
                                                position: animation.drive(
                                                  tween,
                                                ),
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
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.4),
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
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Search installed apps...",
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withOpacity(0.8),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // We can use the TechStackFilter here too, but since the filtering logic resides in SearchPage provider which depends on search scope...
                            // Actually filteredAppsProvider is global/shared in search_provider.
                            // But HomePage uses `filteredApps` variable locally computed from `apps.where((app) => category...)`.
                            // The HomePage DOES NOT use `filteredAppsProvider`.
                            // So adding the filter here won't affect the list unless we update HomePage logic too.
                            // The prompt says "and this same thing can also be replicated to the search page also".
                            // This implies it should be on HomePage first.
                            // However, HomePage currently only filters by Category.
                            // Let's assume we should just navigate to SearchPage when this is clicked for now to avoid major refactor of HomePage provider logic, OR we refactor HomePage to observe the tech stack filter too.
                            // The prompt says "near the search bar add a kind of a icon button... this same thing can also be replicated to the search page".
                            // Let's add the button. For now let it open the filter.
                            const TechStackFilter(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Compact Category Slider
                        const CategorySlider(
                          isCompact: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                filteredApps.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.app_blocking_outlined,
                                size: 64,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No apps found matching criteria",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => AppCard(app: filteredApps[index]),
                          childCount: filteredApps.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => const AppsListSkeleton(key: ValueKey('loading')),
          error: (err, stack) => Center(
            key: const ValueKey('error'),
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
      ),
    );
  }
}
