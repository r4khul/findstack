import 'package:flutter/material.dart';

import '../../../../core/navigation/navigation.dart';
import '../../../apps/domain/entities/device_app.dart';
import 'analytics_app_icon.dart';

class StorageAppItem extends StatelessWidget {
  final DeviceApp app;

  final double percent;

  final int index;

  final bool isTouched;

  final VoidCallback onTapDown;

  final VoidCallback onTapCancel;

  const StorageAppItem({
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

    return GestureDetector(
      onTap: () => AppRouteFactory.toAppDetails(context, app),
      onTapDown: (_) => onTapDown(),
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        ),
        child: Column(
          children: [
            _buildMainRow(theme),
            if (isTouched) _buildExpandedDetails(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRow(ThemeData theme) {
    return Row(
      children: [
        AnalyticsAppIcon(app: app, size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
                    _formatBytes(app.size),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildProgressBar(theme),
            ],
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
        FractionallySizedBox(
          widthFactor: percent.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(ThemeData theme) {
    final internalCache = app.cacheSize >= app.externalCacheSize
        ? app.cacheSize - app.externalCacheSize
        : app.cacheSize;

    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMicroStat(theme, 'Code & OBB', app.appSize),
            _buildMicroStat(theme, 'User Data', app.dataSize),
            _buildMicroStat(theme, 'Total Cache', app.cacheSize),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMicroStat(theme, 'Internal Cache', internalCache),
              Container(
                width: 1,
                height: 20,
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
              _buildSmallMicroStat(
                theme,
                'External Cache',
                app.externalCacheSize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMicroStat(ThemeData theme, String label, int bytes) {
    return Column(
      children: [
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMicroStat(ThemeData theme, String label, int bytes) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
