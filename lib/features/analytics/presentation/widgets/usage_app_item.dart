import 'package:flutter/material.dart';

import '../../../../core/navigation/navigation.dart';
import '../../../apps/domain/entities/device_app.dart';
import 'analytics_app_icon.dart';

class UsageAppItem extends StatelessWidget {
  final DeviceApp app;

  final double percent;

  final int index;

  final bool isTouched;

  final VoidCallback onTapDown;

  final VoidCallback onTapCancel;

  const UsageAppItem({
    super.key,
    required this.app,
    required this.percent,
    required this.index,
    required this.isTouched,
    required this.onTapDown,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => AppRouteFactory.toAppDetails(context, app),
        onTapDown: (_) => onTapDown(),
        onTapCancel: onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isTouched
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isTouched
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: isTouched
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Hero(
                tag: app.packageName,
                transitionOnUserGestures: true,
                createRectTween: (begin, end) {
                  return MaterialRectCenterArcTween(begin: begin, end: end);
                },
                flightShuttleBuilder:
                    (
                      flightContext,
                      animation,
                      flightDirection,
                      fromHeroContext,
                      toHeroContext,
                    ) {
                      return Material(
                        type: MaterialType.transparency,
                        child: toHeroContext.widget,
                      );
                    },
                child: AnalyticsAppIcon(app: app, size: 48),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildContent(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                app.appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressBar(theme),
        const SizedBox(height: 6),
        Text(
          _formatDuration(Duration(milliseconds: app.totalTimeInForeground)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 500),
          widthFactor: percent,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}
