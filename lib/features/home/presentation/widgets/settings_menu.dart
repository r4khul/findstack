import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        Scaffold.of(context).openEndDrawer();
      },
      style: IconButton.styleFrom(
        padding: const EdgeInsets.only(left: 8),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
      ),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
