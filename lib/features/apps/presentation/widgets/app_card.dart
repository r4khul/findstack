import 'package:flutter/material.dart';
import '../../domain/entities/device_app.dart';
import '../pages/app_details_page.dart';
import 'package:intl/intl.dart';

class AppCard extends StatelessWidget {
  final DeviceApp app;

  const AppCard({super.key, required this.app});

  Color _getStackColor(String stack, bool isDark) {
    if (stack == "Flutter")
      return isDark ? const Color(0xFF42A5F5) : const Color(0xFF02569B);
    if (stack == "React Native")
      return isDark ? const Color(0xFF61DAFB) : const Color(0xFF0D47A1);
    // ... same as before
    return Colors.grey;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return "${duration.inMinutes}m";
    } else {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stackColor = _getStackColor(app.stack, isDark);
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AppDetailsPage(app: app)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: stackColor.withOpacity(0.1),
                    backgroundImage: app.icon != null
                        ? MemoryImage(app.icon!)
                        : null,
                    child: app.icon == null
                        ? Text(
                            app.appName.isNotEmpty
                                ? app.appName[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              color: stackColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: "UncutSans",
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: stackColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: stackColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                app.stack,
                                style: TextStyle(
                                  color: stackColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (app.totalTimeInForeground > 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_filled,
                                size: 14,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(app.totalUsageDuration),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // The content that was previously in ExpansionTile's children
              // This part will now always be visible or can be moved to AppDetailsPage
              // For now, let's keep it here as a summary, but the primary action is navigation.
              // If the goal is to make the card a summary and navigate to details,
              // then this detailed section should probably be removed from the card itself.
              // For this change, I'll remove the detailed section from the card
              // as the instruction implies the card itself navigates to a details page.
              // The original ExpansionTile children content is now implicitly part of AppDetailsPage.
            ],
          ),
        ),
      ),
    );
  }
}
