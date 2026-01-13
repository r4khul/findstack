library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// A floating action button for scrolling back to top of a list.
class BackToTopFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVisible;

  const BackToTopFab({
    super.key,
    required this.onPressed,
    required this.isVisible,
  });

  static const double _size = 56.0;
  static const double _blurSigma = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: AppDurations.standard,
      curve: Curves.easeOutBack,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: AppSpacing.xl,
          right: AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.circular),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: Container(
              height: _size,
              width: _size,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(AppOpacity.light)
                    : Colors.black.withOpacity(AppOpacity.subtle),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(
                    AppOpacity.light,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(AppBorderRadius.circular),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
