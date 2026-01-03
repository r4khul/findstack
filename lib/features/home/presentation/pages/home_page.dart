import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/apps_list_skeleton.dart';
import '../../../search/presentation/providers/tech_stack_provider.dart';
import '../widgets/home_sliver_delegate.dart';
import '../widgets/back_to_top_fab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 300 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final theme = Theme.of(context);

    // Calculate heights
    // Search(50) + V-Spacing(12) + Category(40) + V-Spacing(12) = 114
    // + Toolbar(56) = 170 + Top Padding
    final topPadding = MediaQuery.of(context).padding.top;
    final minHeight = 170.0 + topPadding;
    final maxHeight = 260.0 + topPadding;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: BackToTopFab(
        isVisible: _showBackToTop,
        onPressed: _scrollToTop,
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
              controller: _scrollController,
              key: const ValueKey('data'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeSliverDelegate(
                    appCount: apps.length,
                    expandedHeight: maxHeight,
                    collapsedHeight: minHeight,
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
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          20 + MediaQuery.of(context).padding.bottom,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(app: filteredApps[index]),
                            ),
                            childCount: filteredApps.length,
                          ),
                        ),
                      ),
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
