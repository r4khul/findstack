import 'package:flutter/material.dart';

/// Section header widget for drawer content groups.
///
/// Displays an uppercase label with primary color styling.
/// Used to visually separate different sections in the drawer.
class DrawerSectionHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Creates a drawer section header.
  const DrawerSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontSize: 11,
          color: theme.colorScheme.primary.withOpacity(0.6),
        ),
      ),
    );
  }
}
