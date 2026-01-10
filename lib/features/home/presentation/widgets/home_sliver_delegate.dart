import 'package:flutter/material.dart';

import '../../../apps/presentation/widgets/category_slider.dart';
import 'sliver/home_search_bar.dart';
import 'sliver/home_stats_section.dart';
import 'sliver/home_top_app_bar.dart';

/// Sliver persistent header delegate for the home page.
///
/// Manages the collapsible header behavior with smooth transitions between
/// expanded and collapsed states. The header contains:
/// - Stats section (fades out on scroll)
/// - Search bar and category filter (pinned)
/// - Top app bar with logo transition (pinned)
///
/// ## Transition Behavior
/// - Stats fade out quickly as scroll begins (3x multiplier)
/// - Title transitions to logo icon when header is 60-90% collapsed
/// - Border appears when fully collapsed
class HomeSliverDelegate extends SliverPersistentHeaderDelegate {
  /// Total number of installed apps.
  final int appCount;

  /// Maximum header height when fully expanded.
  final double expandedHeight;

  /// Minimum header height when fully collapsed.
  final double collapsedHeight;

  /// Whether to show skeleton loading state.
  final bool isLoading;

  /// Creates a home sliver delegate.
  const HomeSliverDelegate({
    required this.appCount,
    required this.expandedHeight,
    required this.collapsedHeight,
    this.isLoading = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    // Calculate scroll progress (0.0 = expanded, 1.0 = collapsed)
    final progress = shrinkOffset / (maxExtent - minExtent);
    final percent = progress.clamp(0.0, 1.0);

    // Title to logo transition (activates at 60-90% collapsed)
    final titleLogoTransition = ((percent - 0.6) / 0.3).clamp(0.0, 1.0);

    // Stats fade out quickly (3x multiplier)
    final statsOpacity = (1.0 - (percent * 3)).clamp(0.0, 1.0);

    // Background opacity based on scroll position
    final backgroundOpacity = percent > 0.8 ? 0.9 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(
              percent > 0.95 ? 0.1 : 0.0,
            ),
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // Stats section (fades out on scroll)
          _buildStatsSection(context, topPadding, shrinkOffset, statsOpacity),

          // Search bar and categories (pinned at bottom)
          _buildSearchSection(context),

          // Top app bar (pinned at top)
          _buildTopAppBar(context, backgroundOpacity, titleLogoTransition),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    double topPadding,
    double shrinkOffset,
    double opacity,
  ) {
    return Positioned(
      top: topPadding + 60 - (shrinkOffset * 0.8),
      left: 20,
      child: Opacity(
        opacity: opacity,
        child: HomeStatsSection(appCount: appCount, isLoading: isLoading),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: HomeSearchBar(),
            ),
            SizedBox(height: 12),
            CategorySlider(
              isCompact: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    double backgroundOpacity,
    double transitionProgress,
  ) {
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: theme.scaffoldBackgroundColor.withOpacity(backgroundOpacity),
        child: HomeTopAppBar(
          appCount: appCount,
          transitionProgress: transitionProgress,
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(HomeSliverDelegate oldDelegate) {
    return oldDelegate.appCount != appCount ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.isLoading != isLoading;
  }
}
