import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onTap;
  final bool isLoading;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: theme.colorScheme.onSurface),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isGranted
                          ? Colors.transparent
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(100),
                      border: isGranted
                          ? Border.all(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      isGranted ? "Granted" : "Allow",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isGranted
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
