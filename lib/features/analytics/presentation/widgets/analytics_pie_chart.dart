import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../apps/domain/entities/device_app.dart';
import 'analytics_app_icon.dart';
import 'constants.dart';

class AnalyticsPieChart extends StatelessWidget {
  final List<DeviceApp> apps;

  final int total;

  final int otherValue;

  final int touchedIndex;

  final ValueChanged<int> onSectionTouched;

  final int Function(DeviceApp) getValue;

  final String Function(int) formatTotal;

  final String centerLabel;

  const AnalyticsPieChart({
    super.key,
    required this.apps,
    required this.total,
    required this.otherValue,
    required this.touchedIndex,
    required this.onSectionTouched,
    required this.getValue,
    required this.formatTotal,
    this.centerLabel = 'Total',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (total == 0) return const SizedBox.shrink();

    final centerInfo = _getCenterInfo(theme);

    return SizedBox(
      height: ChartConfig.chartHeight,
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
                    if (event is FlTapUpEvent && touchedIndex != -1) {
                      onSectionTouched(-1);
                    }
                    return;
                  }
                  final newIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (touchedIndex != newIndex && newIndex >= 0) {
                    onSectionTouched(newIndex);
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: ChartConfig.sectionsSpace,
              centerSpaceRadius: ChartConfig.centerSpaceRadius,
              sections: _generateSections(theme),
            ),
            duration: AnalyticsAnimationDurations.chart,
            curve: Curves.easeOutCubic,
          ),
          _buildCenterDisplay(theme, centerInfo),
        ],
      ),
    );
  }

  _CenterInfo _getCenterInfo(ThemeData theme) {
    if (touchedIndex != -1 && touchedIndex < apps.length) {
      final app = apps[touchedIndex];
      final percentage = (getValue(app) / total) * 100;
      return _CenterInfo(
        topText: '${percentage.toStringAsFixed(1)}%',
        bottomText: app.appName,
      );
    } else if (touchedIndex == apps.length && otherValue > 0) {
      final percentage = (otherValue / total) * 100;
      return _CenterInfo(
        topText: '${percentage.toStringAsFixed(1)}%',
        bottomText: 'Others',
      );
    }
    return _CenterInfo(topText: centerLabel, bottomText: formatTotal(total));
  }

  Widget _buildCenterDisplay(ThemeData theme, _CenterInfo info) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: AnalyticsAnimationDurations.fast,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(
                Tween(
                  begin: 0.9,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey('$touchedIndex'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.topText,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
                color: theme.colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                info.bottomText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(ThemeData theme) {
    final sections = <PieChartSectionData>[];
    final showBadges = apps.length <= 25;

    for (int i = 0; i < apps.length; i++) {
      final isTouched = i == touchedIndex;
      final radius = isTouched
          ? ChartConfig.sectionRadiusTouched
          : ChartConfig.sectionRadius;
      final app = apps[i];
      final value = getValue(app).toDouble();

      final normalizedIndex = i / (apps.isNotEmpty ? apps.length : 1);
      final opacity = 0.9 - (normalizedIndex * 0.7);
      final color = theme.colorScheme.primary.withValues(
        alpha: opacity.clamp(0.15, 0.9),
      );

      final badgeSize = isTouched
          ? AnalyticsIconSizes.badgeLg
          : (apps.length > 10
                ? AnalyticsIconSizes.badgeSm
                : AnalyticsIconSizes.badgeMd);

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: radius,
          badgeWidget: showBadges
              ? AnalyticsAppIcon(app: app, size: badgeSize, addBorder: true)
              : null,
          badgePositionPercentageOffset: ChartConfig.badgePositionOffset,
          borderSide: isTouched
              ? BorderSide(color: theme.colorScheme.surface, width: 2)
              : const BorderSide(color: Colors.transparent),
        ),
      );
    }

    if (otherValue > 0) {
      final isTouched = apps.length == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      sections.add(
        PieChartSectionData(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          value: otherValue.toDouble(),
          title: '',
          radius: radius,
          badgeWidget: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          badgePositionPercentageOffset: ChartConfig.badgePositionOffset,
        ),
      );
    }

    return sections;
  }
}

class _CenterInfo {
  final String topText;
  final String bottomText;

  const _CenterInfo({required this.topText, required this.bottomText});
}
