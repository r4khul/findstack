import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/premium_app_bar.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

class StatisticsDialog extends ConsumerStatefulWidget {
  const StatisticsDialog({super.key});

  @override
  ConsumerState<StatisticsDialog> createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends ConsumerState<StatisticsDialog> {
  int _touchedIndex = -1;
  int _showTopCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 750),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PremiumAppBar(
              title: "Usage Statistics",
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
              actions: [_buildFilterAction(theme), const SizedBox(width: 8)],
            ),
            body: appsAsync.when(
              data: (apps) => _buildContent(context, apps),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterAction(ThemeData theme) {
    return PopupMenuButton<int>(
      initialValue: _showTopCount,
      onSelected: (value) => setState(() => _showTopCount = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 5, child: Text("Top 5")),
        const PopupMenuItem(value: 10, child: Text("Top 10")),
        const PopupMenuItem(value: 20, child: Text("Top 20")),
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Top $_showTopCount",
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<DeviceApp> apps) {
    final theme = Theme.of(context);
    final validApps = apps.where((a) => a.totalTimeInForeground > 0).toList();
    if (validApps.isEmpty) {
      return const Center(child: Text("No usage data available yet."));
    }

    validApps.sort(
      (a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground),
    );

    final totalUsage = validApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );

    final topApps = validApps.take(_showTopCount).toList();
    final topUsage = topApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );
    final otherUsage = totalUsage - topUsage;

    // Center text calculation
    String centerTopText = "Total";
    String centerBottomText = _formatDuration(
      Duration(milliseconds: totalUsage),
    );

    if (_touchedIndex != -1 && _touchedIndex < topApps.length) {
      final app = topApps[_touchedIndex];
      final percentage = (app.totalTimeInForeground / totalUsage) * 100;
      centerTopText = "${percentage.toStringAsFixed(1)}%";
      centerBottomText = app.appName;
    } else if (_touchedIndex == topApps.length && otherUsage > 0) {
      // Touched "Others"
      final percentage = (otherUsage / totalUsage) * 100;
      centerTopText = "${percentage.toStringAsFixed(1)}%";
      centerBottomText = "Others";
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Pie Chart Area
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        if (event is FlTapUpEvent && _touchedIndex != -1) {
                          setState(() => _touchedIndex = -1);
                        }
                        return;
                      }
                      final newIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (_touchedIndex != newIndex) {
                        setState(() => _touchedIndex = newIndex);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: _generateSections(
                    context,
                    topApps,
                    otherUsage,
                    totalUsage,
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 350),
                swapAnimationCurve: Curves.easeOutQuad,
              ),
              // Center Info
              IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey("$_touchedIndex"),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerTopText,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          fontSize: 28,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          centerBottomText,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // List View
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: topApps.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = topApps[index];
                  final percent = (app.totalTimeInForeground / totalUsage);
                  final isTouched = index == _touchedIndex;

                  return GestureDetector(
                    onTap: () => _navigateToApp(context, app),
                    onTapDown: (_) => setState(() => _touchedIndex = index),
                    onTapCancel: () => setState(() => _touchedIndex = -1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isTouched
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTouched
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: app.packageName,
                            child: _AppIcon(app: app, size: 40),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        app.appName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "${(percent * 100).toStringAsFixed(1)}%",
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(4),
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    } else {
      return "${duration.inMinutes}m";
    }
  }

  void _navigateToApp(BuildContext context, DeviceApp app) {
    // Use centralized navigation for consistent premium transitions
    AppRouteFactory.toAppDetails(context, app);
  }

  List<PieChartSectionData> _generateSections(
    BuildContext context,
    List<DeviceApp> displayApps,
    int otherUsage,
    int totalUsage,
  ) {
    final theme = Theme.of(context);
    List<PieChartSectionData> sections = [];
    final bool showBadges = displayApps.length <= 10;

    for (int i = 0; i < displayApps.length; i++) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final app = displayApps[i];
      final value = app.totalTimeInForeground.toDouble();

      // Use a gradient-like palette or cycling colors
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.tertiary,
        theme.colorScheme.secondary,
        theme.colorScheme.error,
        Colors.orange,
        Colors.purple,
        Colors.teal,
      ];
      final color = colors[i % colors.length];

      sections.add(
        PieChartSectionData(
          color: color.withOpacity(0.9),
          value: value,
          title: '',
          radius: radius,
          badgeWidget: showBadges && isTouched
              ? _AppIcon(app: app, size: 32, addBorder: true)
              : (showBadges ? _AppIcon(app: app, size: 24) : null),
          badgePositionPercentageOffset: 0.98,
          borderSide: isTouched
              ? BorderSide(color: theme.colorScheme.surface, width: 2)
              : BorderSide(color: Colors.transparent),
        ),
      );
    }

    if (otherUsage > 0) {
      final isTouched = displayApps.length == _touchedIndex;
      final radius = isTouched ? 55.0 : 45.0;

      sections.add(
        PieChartSectionData(
          color: theme.colorScheme.surfaceContainerHighest,
          value: otherUsage.toDouble(),
          title: '',
          radius: radius,
          badgeWidget: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          badgePositionPercentageOffset: 0.98,
        ),
      );
    }

    return sections;
  }
}

class _AppIcon extends StatelessWidget {
  final DeviceApp app;
  final double size;
  final bool addBorder;

  const _AppIcon({
    required this.app,
    required this.size,
    this.addBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: addBorder ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: addBorder
            ? [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: app.icon != null
            ? Image.memory(app.icon!, fit: BoxFit.cover, gaplessPlayback: true)
            : const Icon(Icons.android, size: 16),
      ),
    );
  }
}
