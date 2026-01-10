import 'dart:ui';
import 'package:flutter/material.dart';

class BackToTopFab extends StatelessWidget {
  final VoidCallback onPressed;

  final bool isVisible;

  const BackToTopFab({
    super.key,
    required this.onPressed,
    required this.isVisible,
  });

  static const double _size = 56.0;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  static const double _blurSigma = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: _animationDuration,
      curve: Curves.easeOutBack,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, right: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: Container(
              height: _size,
              width: _size,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(30),
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
