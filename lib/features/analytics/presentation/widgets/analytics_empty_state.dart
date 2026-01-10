import 'package:flutter/material.dart';

/// Empty state widget for analytics pages.
///
/// Shows when no data is available or no search results found.
/// Displays an icon and a message.
class AnalyticsEmptyState extends StatelessWidget {
  /// Message to display.
  final String message;

  /// Icon to display.
  final IconData icon;

  /// Creates an analytics empty state.
  const AnalyticsEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
