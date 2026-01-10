import 'package:flutter/material.dart';

/// Roast section displaying total usage with a humorous message.
///
/// Shows the total screen time in a styled card with a "lifespan consumed"
/// badge and a contextual "roast" message based on the duration.
class UsageRoastCard extends StatelessWidget {
  /// Total usage duration.
  final Duration totalUsage;

  /// Creates a usage roast card.
  const UsageRoastCard({super.key, required this.totalUsage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roast = _getRoastMessage(totalUsage);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.02),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _formatDuration(totalUsage),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LIFESPAN CONSUMED',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              roast,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a contextual roast message based on hours used.
  static String _getRoastMessage(Duration duration) {
    final hours = duration.inHours;

    if (hours > 1000) {
      return "That's... a significant portion of your finite existence.";
    } else if (hours > 500) {
      return 'You could have walked to Mordor and back.';
    } else if (hours > 100) {
      return 'Think of the books you could have read.';
    } else if (hours > 24) {
      return 'A whole day gone. Poof.';
    } else if (hours > 5) {
      return "Productivity taking a hit, isn't it?";
    } else {
      return 'Surprisingly productive... or just installed?';
    }
  }

  /// Formats duration to a readable string.
  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }

  /// Static method to get roast message (for sharing poster).
  static String getRoastForDuration(Duration duration) =>
      _getRoastMessage(duration);
}
