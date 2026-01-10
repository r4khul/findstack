/// A glassmorphic bottom action bar for the update check page.
///
/// This widget provides a floating action bar at the bottom of the screen
/// with blur effects and customizable content.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'constants.dart';

/// A floating bottom action bar with glassmorphism styling.
///
/// This bar can display either a custom child widget or a standard
/// filled button with optional loading state.
///
/// ## Usage
/// ```dart
/// UpdateBottomActionBar(
///   label: "Check Again",
///   icon: Icons.refresh_rounded,
///   onPressed: _handleRefresh,
/// )
/// ```
///
/// Or with a custom child:
/// ```dart
/// UpdateBottomActionBar(
///   child: UpdateDownloadButton(...),
/// )
/// ```
class UpdateBottomActionBar extends StatelessWidget {
  /// Optional button label text.
  final String? label;

  /// Optional button icon.
  final IconData? icon;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether to use secondary (muted) styling.
  final bool isSecondary;

  /// Optional custom child widget to display instead of standard button.
  final Widget? child;

  /// Creates an update bottom action bar.
  const UpdateBottomActionBar({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        UpdateSpacing.standard,
        0,
        UpdateSpacing.standard,
        UpdateSpacing.standard,
      ),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
          child: BackdropFilter(
            filter: standardBlurFilter,
            child: Container(
              padding: const EdgeInsets.all(UpdateSpacing.md),
              decoration: _buildDecoration(theme, isDark),
              child: child ?? _buildButton(theme),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: theme.colorScheme.surface.withOpacity(UpdateOpacity.veryHigh),
      borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            isDark ? UpdateOpacity.standard : UpdateOpacity.light,
          ),
          blurRadius: UpdateBlur.shadow,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(UpdateOpacity.light)
            : Colors.black.withOpacity(UpdateOpacity.subtle),
      ),
    );
  }

  Widget _buildButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isSecondary
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(
                UpdateOpacity.high,
              )
            : theme.colorScheme.primary,
        foregroundColor: isSecondary
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
          side: isSecondary
              ? BorderSide(
                  color: theme.colorScheme.outline.withOpacity(
                    UpdateOpacity.light,
                  ),
                )
              : BorderSide.none,
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: UpdateSizes.iconSizeSmall,
              height: UpdateSizes.iconSizeSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isSecondary
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimary,
              ),
            )
          : Icon(icon, size: UpdateSizes.iconSize),
      label: Text(
        label ?? "",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
