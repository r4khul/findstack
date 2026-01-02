import 'package:flutter/material.dart';
import '../../domain/device_app.dart';

class AppCard extends StatelessWidget {
  final DeviceApp app;

  const AppCard({super.key, required this.app});

  Color _getStackColor(String stack, bool isDark) {
    if (stack == "Flutter")
      return isDark ? const Color(0xFF42A5F5) : const Color(0xFF02569B);
    if (stack == "React Native")
      return isDark ? const Color(0xFF61DAFB) : const Color(0xFF0D47A1);
    if (stack == "Xamarin") return const Color(0xFF3498DB);
    if (stack == "Ionic/Cordova" || stack == "Capacitor/Ionic")
      return const Color(0xFF4E8EF7);
    if (stack == "Unity") return isDark ? Colors.white : Colors.black;
    return Colors.grey;
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
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: stackColor.withOpacity(0.1),
          child: Text(
            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : "?",
            style: TextStyle(
              color: stackColor,
              fontWeight: FontWeight.bold,
              fontFamily: "UncutSans",
            ),
          ),
        ),
        title: Text(
          app.appName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              app.packageName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stackColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: stackColor.withOpacity(0.3),
                  width: 1,
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
          ],
        ),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: theme.dividerTheme.color),
                  const SizedBox(height: 8),
                  Text(
                    "DETAILS",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Version", style: theme.textTheme.bodyMedium),
                      Text(
                        app.version,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (app.nativeLibraries.isNotEmpty) ...[
                    Text(
                      "DETECTED LIBRARIES",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: app.nativeLibraries.map((lib) {
                        return Chip(
                          label: Text(
                            lib,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(color: theme.colorScheme.outline),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(0),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
