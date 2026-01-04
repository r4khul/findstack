import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/storage_breakdown.dart';
import '../providers/storage_provider.dart';

/// Detailed storage breakdown dialog for an app.
/// Shows comprehensive breakdown with confidence level and limitations.
class StorageBreakdownDialog extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;

  const StorageBreakdownDialog({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  ConsumerState<StorageBreakdownDialog> createState() =>
      _StorageBreakdownDialogState();
}

class _StorageBreakdownDialogState
    extends ConsumerState<StorageBreakdownDialog> {
  bool _isDetailed = false;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Fetch basic breakdown on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storageBreakdownProvider.notifier)
          .getBreakdown(widget.packageName, detailed: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(storageBreakdownProvider);
    final breakdown = state.getBreakdown(widget.packageName);
    final isLoading = state.isLoading(widget.packageName);
    final error = state.getError(widget.packageName);

    return Dialog(
      backgroundColor: Colors.transparent, // Transparent for custom container
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            // Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: _buildContent(theme, breakdown, isLoading, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    StorageBreakdown? breakdown,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Analysis Failed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (breakdown == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Size Card
          _buildTotalCard(theme, breakdown),
          const SizedBox(height: 24),

          // Chart Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "DISTRIBUTION",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildBreakdownChart(theme, breakdown),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Breakdown List
          _buildBreakdownList(theme, breakdown),
          const SizedBox(height: 16),

          // Media and Other Sections
          if (breakdown.mediaSize > 0) ...[
            _buildMediaBreakdown(theme, breakdown),
            const SizedBox(height: 16),
          ],

          // Metadata & Limitations
          _buildMetadata(theme, breakdown),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActions(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Storage Analysis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme, StorageBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SIZE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatBytes(breakdown.totalCombined),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              _buildConfidenceBadge(theme, breakdown.confidenceLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(ThemeData theme, double confidence) {
    final color = confidence > 0.8
        ? Colors.green
        : confidence > 0.5
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence > 0.8
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${(confidence * 100).toInt()}% Conf.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownChart(ThemeData theme, StorageBreakdown breakdown) {
    final sections = <PieChartSectionData>[];
    final data = [
      ('APK', breakdown.apkSize, Colors.blue),
      ('Data', breakdown.appDataInternal, Colors.green),
      (
        'Cache',
        breakdown.cacheInternal + breakdown.cacheExternal,
        Colors.orange,
      ),
      if (breakdown.obbSize > 0) ('OBB', breakdown.obbSize, Colors.purple),
      if (breakdown.mediaSize > 0) ('Media', breakdown.mediaSize, Colors.pink),
      if (breakdown.databasesSize > 0)
        ('DB', breakdown.databasesSize, Colors.cyan),
      if (breakdown.logsSize > 0) ('Logs', breakdown.logsSize, Colors.amber),
      if (breakdown.residualSize > 0)
        ('Other', breakdown.residualSize, theme.colorScheme.outline),
    ];

    for (var i = 0; i < data.length; i++) {
      final (label, size, color) = data[i];
      if (size > 0) {
        final isTouched = _touchedIndex == i;
        sections.add(
          PieChartSectionData(
            color: color,
            value: size.toDouble(),
            title: isTouched
                ? '${(size / breakdown.totalCombined * 100).toInt()}%'
                : '',
            titleStyle: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            radius: isTouched ? 45 : 35,
            borderSide: isTouched
                ? BorderSide(color: theme.colorScheme.surface, width: 2)
                : BorderSide.none,
          ),
        );
      }
    }

    if (sections.isEmpty) return const SizedBox();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 60,
              sectionsSpace: 4,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!mounted) return;
                  if (event is FlTapUpEvent &&
                      response?.touchedSection != null) {
                    setState(() {
                      if (_touchedIndex ==
                          response!.touchedSection!.touchedSectionIndex) {
                        _touchedIndex = -1;
                      } else {
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      }
                    });
                  } else if (response?.touchedSection == null) {
                    // Do nothing on tap nowhere, or maybe reset?
                    // Let's keep the selection if user drags out
                  }
                },
              ),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          ),

          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _touchedIndex >= 0 && _touchedIndex < data.length
                    ? data[_touchedIndex].$1
                    : "Total",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _touchedIndex >= 0 && _touchedIndex < data.length
                    ? _formatBytes(data[_touchedIndex].$2)
                    : _formatBytes(breakdown.totalCombined),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(ThemeData theme, StorageBreakdown breakdown) {
    final items = [
      ('APK File', breakdown.apkSize, Icons.android_rounded, Colors.blue),
      (
        'App Data',
        breakdown.appDataInternal,
        Icons.folder_rounded,
        Colors.green,
      ),
      (
        'All Cache',
        breakdown.cacheInternal + breakdown.cacheExternal,
        Icons.cached_rounded,
        Colors.orange,
      ),
      if (breakdown.obbSize > 0)
        (
          'OBB Files',
          breakdown.obbSize,
          Icons.extension_rounded,
          Colors.purple,
        ),
      if (breakdown.mediaSize > 0)
        ('Media', breakdown.mediaSize, Icons.perm_media_rounded, Colors.pink),
      if (breakdown.databasesSize > 0)
        (
          'Databases',
          breakdown.databasesSize,
          Icons.storage_rounded,
          Colors.cyan,
        ),
      if (breakdown.logsSize > 0)
        ('Logs', breakdown.logsSize, Icons.description_rounded, Colors.amber),
      if (breakdown.residualSize > 0)
        (
          'Other',
          breakdown.residualSize,
          Icons.more_horiz_rounded,
          theme.colorScheme.outline,
        ),
    ];

    return Column(
      children: items
          .map(
            (item) =>
                _buildBreakdownItem(theme, item.$1, item.$2, item.$3, item.$4),
          )
          .toList(),
    );
  }

  Widget _buildBreakdownItem(
    ThemeData theme,
    String label,
    int size,
    IconData icon,
    Color color,
  ) {
    if (size == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatBytes(size),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontFamily: 'monospace', // Monospace for better alignment
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBreakdown(ThemeData theme, StorageBreakdown breakdown) {
    if (breakdown.mediaBreakdown.total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.perm_media_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Media Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (breakdown.mediaBreakdown.images > 0)
            _buildSmallStat('Images', breakdown.mediaBreakdown.images, theme),
          if (breakdown.mediaBreakdown.videos > 0)
            _buildSmallStat('Videos', breakdown.mediaBreakdown.videos, theme),
          if (breakdown.mediaBreakdown.audio > 0)
            _buildSmallStat('Audio', breakdown.mediaBreakdown.audio, theme),
          if (breakdown.mediaBreakdown.documents > 0)
            _buildSmallStat(
              'Documents',
              breakdown.mediaBreakdown.documents,
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, int size, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _formatBytes(size),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme, StorageBreakdown breakdown) {
    if (breakdown.limitations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Limitations',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...breakdown.limitations.map(
            (limitation) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      limitation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          setState(() => _isDetailed = !_isDetailed);
          ref
              .read(storageBreakdownProvider.notifier)
              .getBreakdown(
                widget.packageName,
                detailed: _isDetailed,
                forceRefresh: true,
              );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDetailed
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.primary,
          foregroundColor: _isDetailed
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDetailed ? Icons.flash_on_rounded : Icons.search_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isDetailed ? 'Quick Scan' : 'Deep Scan',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
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

  @override
  void dispose() {
    ref
        .read(storageBreakdownProvider.notifier)
        .cancelAnalysis(widget.packageName);
    super.dispose();
  }
}
