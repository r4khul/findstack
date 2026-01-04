import 'settings_menu.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter/material.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../apps/presentation/widgets/category_slider.dart';
import '../../../search/presentation/widgets/tech_stack_filter.dart';
import 'scan_button.dart';

class HomeSliverDelegate extends SliverPersistentHeaderDelegate {
  final int appCount;
  final double expandedHeight;
  final double collapsedHeight;
  final bool isLoading;

  HomeSliverDelegate({
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
    final progress = shrinkOffset / (maxExtent - minExtent);
    final percent = progress.clamp(0.0, 1.0);
    // Transition phase for Title -> Logo (0.0 to 1.0)
    final t = ((percent - 0.6) / 0.3).clamp(0.0, 1.0);

    // Fade out stats quickly so they don't overlap with sliding up content
    final statsOpacity = (1.0 - (percent * 3)).clamp(0.0, 1.0);

    final isDark = theme.brightness == Brightness.dark;

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
          // 1. Stats Section (Expanded Only)
          // Fades out very quickly
          Positioned(
            top: MediaQuery.of(context).padding.top + 60 - (shrinkOffset * 0.8),
            left: 20,
            child: Opacity(
              opacity: statsOpacity,
              child: Skeletonizer(
                enabled: isLoading,
                effect: ShimmerEffect(
                  baseColor: isDark
                      ? const Color(0xFF303030)
                      : const Color(0xFFE0E0E0),
                  highlightColor: isDark
                      ? const Color(0xFF424242)
                      : const Color(0xFFFAFAFA),
                  duration: const Duration(milliseconds: 1500),
                ),
                textBoneBorderRadius: TextBoneBorderRadius(
                  BorderRadius.circular(4),
                ),
                justifyMultiLineText: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Device has",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? "000 Installed Apps"
                          : "$appCount Installed Apps",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Search Bar & Categories (Sticky)
          // Always pinned to the bottom of the header
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Use centralized navigation for consistent premium transitions
                              AppRouteFactory.toSearch(context);
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2, // Subtle border
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.03,
                                    ), // Lighter shadow
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
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Search installed apps...",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.8),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const TechStackFilter(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const CategorySlider(
                    isCompact: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top App Bar (Sticky Top)
          // Contains Logo/Title and Scan Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: theme.scaffoldBackgroundColor.withOpacity(
                percent > 0.8 ? 0.9 : 0.0, // Fade in background if needed
              ),
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 56, // Standard Toolbar height
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Logo / Title Transition
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Expanded Title (Exiting)
                            Transform.translate(
                              offset: Offset(0, -10 * t),
                              child: Opacity(
                                opacity: (1 - t).clamp(0.0, 1.0),
                                child: Text(
                                  "UnFilter",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Collapsed Logo (Entering)
                            Transform.translate(
                              offset: Offset(0, 10 * (1 - t)),
                              child: Opacity(
                                opacity: t.clamp(0.0, 1.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Image.asset(
                                        _getHeadlineLogo(
                                          theme.brightness == Brightness.dark,
                                        ),
                                        height: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.install_mobile,
                                            size: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$appCount",
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ScanButton(),
                      const SizedBox(width: 4),
                      const SettingsMenu(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeadlineLogo(bool isDark) {
    // According to requirements:
    // White logo for dark background (Dark Mode)
    // Black logo for light background (Light Mode)
    if (isDark) {
      return 'assets/icons/white-unfilter-nobg.png';
    } else {
      return 'assets/icons/black-unfilter-nobg.png';
    }
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(HomeSliverDelegate oldDelegate) {
    return oldDelegate.appCount != appCount ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight;
  }
}
