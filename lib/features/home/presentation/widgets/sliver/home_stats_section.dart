import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../constants.dart';

class HomeStatsSection extends StatelessWidget {
  final int appCount;

  final bool isLoading;

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
