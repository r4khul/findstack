import 'package:flutter/material.dart';

/// Header widget for the app drawer.
///
/// Displays the "Menu" title with a subtitle and a close button.
/// This is a stateless, pure UI composition widget.
class AppDrawerHeader extends StatelessWidget {
  /// Creates a drawer header widget.
  const AppDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Settings & Info',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.3),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
