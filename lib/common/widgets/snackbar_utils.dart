library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// Shows a styled snackbar with an icon and message.
void showPremiumSnackbar({
  required BuildContext context,
  required IconData icon,
  required String message,
  required bool isSuccess,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final iconColor = isSuccess
      ? const Color(0xFF4CAF50)
      : theme.colorScheme.error;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.standard,
              vertical: AppSpacing.standard - 2,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A1A).withOpacity(0.92)
                  : const Color(0xFFF0F0F0).withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(
                  AppOpacity.light,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(
                        AppOpacity.nearlyOpaque,
                      ),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: AppDurations.snackbar,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.standard,
      ),
    ),
  );
}
