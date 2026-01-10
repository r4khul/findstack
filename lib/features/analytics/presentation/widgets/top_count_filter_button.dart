import 'package:flutter/material.dart';

class TopCountFilterButton extends StatelessWidget {
  final int currentCount;

  final ValueChanged<int> onCountSelected;

  const TopCountFilterButton({
    super.key,
    required this.currentCount,
    required this.onCountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<int>(
      initialValue: currentCount,
      onSelected: onCountSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 5, child: Text('Top 5 Apps')),
        PopupMenuItem(value: 10, child: Text('Top 10 Apps')),
        PopupMenuItem(value: 20, child: Text('Top 20 Apps')),
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top $currentCount',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
