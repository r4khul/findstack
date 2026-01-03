import 'dart:ui';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../../features/apps/presentation/pages/app_details_page.dart';

class StatisticsDialog extends ConsumerStatefulWidget {
  const StatisticsDialog({super.key});

  @override
  ConsumerState<StatisticsDialog> createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends ConsumerState<StatisticsDialog> {
  int _touchedIndex = -1;
  int _showTopCount = 5; // Default show top 5

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 750),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Dropdown
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Usage Statistics",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _buildTopSelector(theme),
                ],
              ),
            ),

            Expanded(
              child: appsAsync.when(
                data: (apps) => _buildContent(context, apps),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
              ),
            ),

            // Close Button Footer
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSelector(ThemeData theme) {
    return PopupMenuButton<int>(
      initialValue: _showTopCount,
      onSelected: (value) => setState(() => _showTopCount = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 5, child: Text("Top 5 Apps")),
        const PopupMenuItem(value: 10, child: Text("Top 10 Apps")),
        const PopupMenuItem(value: 25, child: Text("Top 25 Apps")),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Row(
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

    // Logic: Chart shows exactly what's requested (Top 5, 10, 25).
    // "Others" is the rest of the valid apps not in the top list.
    final topApps = validApps.take(_showTopCount).toList();
    final topUsage = topApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );
    final otherUsage = totalUsage - topUsage;

    return Column(
      children: [
        // Pie Chart Area
        SizedBox(
          height: 240,
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
                        if (_touchedIndex != -1)
                          setState(() => _touchedIndex = -1);
                        return;
                      }
                      final newIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (_touchedIndex != newIndex)
                        setState(() => _touchedIndex = newIndex);

                      // Handle touch navigation if touchUp
                      if (event is FlTapUpEvent && newIndex < topApps.length) {
                        _navigateToApp(context, topApps[newIndex]);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _generateSections(
                    context,
                    topApps,
                    otherUsage,
                    totalUsage,
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 600),
                swapAnimationCurve: Curves.easeOutQuint,
              ),
              // Center Info
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touchedIndex != -1 && _touchedIndex < topApps.length
                          ? "${((topApps[_touchedIndex].totalTimeInForeground / totalUsage) * 100).toStringAsFixed(1)}%"
                          : "${validApps.length}",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1,
                            color: theme.colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      _touchedIndex != -1 && _touchedIndex < topApps.length
                          ? "Of total usage"
                          : "Apps Used",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Peak Modern Containerized ListView
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(
              4,
            ), // Inner padding for scrollbar space
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.05),
              ),
            ),
            child: Theme(
              data: theme.copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: MaterialStateProperty.all(
                    theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  radius: const Radius.circular(10),
                  thickness: MaterialStateProperty.all(4),
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: topApps.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final app = topApps[index];
                    final percent = (app.totalTimeInForeground / totalUsage);
                    final isTouchHighlighted = index == _touchedIndex;

                    return GestureDetector(
                      onTap: () => _navigateToApp(context, app),
                      onTapDown: (_) {
                        if (index < topApps.length)
                          setState(() => _touchedIndex = index);
                      },
                      onTapCancel: () => setState(() => _touchedIndex = -1),
                      onTapUp: (_) => setState(() => _touchedIndex = -1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTouchHighlighted
                              ? theme.colorScheme.onSurface.withOpacity(0.08)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isTouchHighlighted
                                ? theme.colorScheme.onSurface.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          boxShadow: isTouchHighlighted
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: app.packageName + "_stats", // Unique tag
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(1),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: app.icon != null
                                      ? Image.memory(
                                          app.icon!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        )
                                      : const Icon(Icons.android, size: 20),
                                ),
                              ),
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
                                                fontSize: 14,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${(percent * 100).toStringAsFixed(1)}%",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontFeatures: [
                                                const FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Monochrome Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 4,
                                      backgroundColor: theme
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.05),
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8), // Monochrome
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
        ),
      ],
    );
  }

  void _navigateToApp(BuildContext context, DeviceApp app) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppDetailsPage(app: app)),
    );
  }

  List<PieChartSectionData> _generateSections(
    BuildContext context,
    List<DeviceApp> displayApps,
    int otherUsage,
    int totalUsage,
  ) {
    final theme = Theme.of(context);
    List<PieChartSectionData> sections = [];

    // Only show badges (icons) if we are not in High Density mode (e.g. top 25)
    // OR show them only for larger slices.
    // For sleekness, let's show icons only for Top 10. For Top 25, it's too crowded.
    final bool showIcons = displayApps.length <= 15;

    for (int i = 0; i < displayApps.length; i++) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final app = displayApps[i];
      final value = app.totalTimeInForeground.toDouble();

      // Monochrome Palette Generation
      // Vary opacity based on rank to distinguish slices
      final double opacity = 1.0 - (i / (displayApps.length + 5));
      final Color sectionColor = theme.colorScheme.primary.withOpacity(
        opacity.clamp(0.2, 1.0),
      );

      sections.add(
        PieChartSectionData(
          color: sectionColor,
          value: value,
          title: '',
          radius: radius,
          // Conditionally show badge
          badgeWidget: showIcons
              ? (isTouched
                    ? _Badge(
                        app.icon,
                        size: 40,
                        borderColor: theme.colorScheme.onSurface,
                      )
                    : _Badge(app.icon, size: 28))
              : null,
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    if (otherUsage > 0) {
      final isTouched = sections.length == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;

      sections.add(
        PieChartSectionData(
          color: theme.colorScheme.surfaceContainerHighest,
          value: otherUsage.toDouble(),
          title: '',
          radius: radius,
          badgeWidget: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            size: 16,
          ),
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    return sections;
  }
}

class _Badge extends StatelessWidget {
  final Uint8List? iconBytes;
  final double size;
  final Color? borderColor;

  const _Badge(this.iconBytes, {required this.size, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2), // White padding
      child: ClipOval(
        child: iconBytes != null
            ? Image.memory(
                iconBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.android, size: 16),
              )
            : const Icon(Icons.android, size: 16),
      ),
    );
  }
}
