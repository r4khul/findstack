import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../constants.dart';

/// Stats section widget displaying the app count.
///
/// Shows "Your Device has X Installed Apps" with skeleton loading support.
/// This section fades out as the header collapses.
class HomeStatsSection extends StatelessWidget {
  /// Total number of installed apps.
  final int appCount;

  /// Whether to show skeleton loading state.
  final bool isLoading;

  /// Creates a home stats section.
  const HomeStatsSection({
    super.key,
    required this.appCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Skeletonizer(
      enabled: isLoading,
      effect: ShimmerEffect(
        baseColor: isDark
            ? HomeShimmerColors.darkBase
            : HomeShimmerColors.lightBase,
        highlightColor: isDark
            ? HomeShimmerColors.darkHighlight
            : HomeShimmerColors.lightHighlight,
        duration: HomeAnimationDurations.shimmer,
      ),
      textBoneBorderRadius: TextBoneBorderRadius(BorderRadius.circular(4)),
      justifyMultiLineText: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Device has',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading ? '000 Installed Apps' : '$appCount Installed Apps',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
