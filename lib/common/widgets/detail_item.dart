library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/constants.dart';

/// A reusable key-value detail item with copy-on-long-press functionality.
class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label'),
            behavior: SnackBarBehavior.floating,
            duration: AppDurations.snackbarQuick,
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(
                        AppOpacity.high,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.standard),
                Flexible(
                  flex: 5,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(AppOpacity.light),
            ),
        ],
      ),
    );
  }
}

/// A simple vertical divider for stats rows.
class StatDivider extends StatelessWidget {
  const StatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 30,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(AppOpacity.medium),
    );
  }
}
