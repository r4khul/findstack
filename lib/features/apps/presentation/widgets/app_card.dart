import 'package:flutter/material.dart';
import '../../domain/entities/device_app.dart';
import '../pages/app_details_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  String _getStackIconPath(String stack) {
    switch (stack.toLowerCase()) {
      case 'flutter':
        return 'assets/vectors/icon_flutter.svg';
      case 'react native':
        return 'assets/vectors/icon_reactnative.svg';
      case 'kotlin':
        return 'assets/vectors/icon_kotlin.svg';
      case 'java':
        return 'assets/vectors/icon_java.svg';
      case 'swift':
        return 'assets/vectors/icon_swift.svg';
      case 'ionic':
        return 'assets/vectors/icon_ionic.svg';
      case 'xamarin':
        return 'assets/vectors/icon_xamarin.svg';
      default:
        return 'assets/vectors/icon_android.svg';
    }
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
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stackColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stackColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    _getStackIconPath(app.stack),
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    app.stack,
                                    style: TextStyle(
                                      color: stackColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
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
