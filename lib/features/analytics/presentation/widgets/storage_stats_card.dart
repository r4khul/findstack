import 'package:flutter/material.dart';

import 'constants.dart';

class StorageStatsCard extends StatelessWidget {
  final int totalSize;

  final int appCodeSize;

  final int dataSize;

  final int cacheSize;

  final bool isFiltered;

  const StorageStatsCard({
    super.key,
    required this.totalSize,
    required this.appCodeSize,
    required this.dataSize,
    required this.cacheSize,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AnalyticsBorderRadius.card),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatBytes(totalSize),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered ? 'FILTERED SIZE' : 'TOTAL CONSUMED',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StorageStatItem(
                label: 'App Code',
                bytes: appCodeSize,
                color: StorageColors.appCode,
              ),
              _StorageStatItem(
                label: 'User Data',
                bytes: dataSize,
                color: StorageColors.userData,
              ),
              _StorageStatItem(
                label: 'Cache',
                bytes: cacheSize,
                color: StorageColors.cache,
              ),
            ],
          ),
        ],
      ),
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

class _StorageStatItem extends StatelessWidget {
  final String label;
  final int bytes;
  final Color color;

  const _StorageStatItem({
    required this.label,
    required this.bytes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, size: 8, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
