import 'package:flutter/material.dart';

class DrawerSectionHeader extends StatelessWidget {
  final String title;

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
