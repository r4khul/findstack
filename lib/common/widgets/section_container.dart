library;

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// A reusable container with consistent padding and background styling.
class SectionContainer extends StatelessWidget {
  final Widget child;
  final bool useAltBackground;

  const SectionContainer({
    super.key,
    required this.child,
    this.useAltBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: useAltBackground
            ? theme.colorScheme.surface
            : (isDark
                  ? Colors.white.withOpacity(AppOpacity.subtle)
                  : Colors.black.withOpacity(AppOpacity.verySubtle)),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: useAltBackground
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(AppOpacity.low),
              )
            : null,
      ),
      child: child,
    );
  }
}
