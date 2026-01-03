import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../domain/entities/app_usage_point.dart';

class UsageChart extends StatefulWidget {
  final List<AppUsagePoint> history;
  final ThemeData theme;
  final bool isDark;

  const UsageChart({
    super.key,
    required this.history,
    required this.theme,
    required this.isDark,
  });

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  String _selectedRange = '1Y'; // 1W, 1M, 3M, 6M, 1Y
  int? _touchedIndex;

  // Processed points for the chart (grouped/filtered)
  late List<AppUsagePoint> _chartPoints;
  // Maximum Y value for scaling
  late double _maxY;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(UsageChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _processData();
    }
  }

  void _processData() {
    final full = widget.history;
    if (full.isEmpty) {
      _chartPoints = [];
      _maxY = 100;
      return;
    }

    // 1. Filter by Range
    final now = DateTime.now();
    Duration rangeDuration;
    switch (_selectedRange) {
      case '1W':
        rangeDuration = const Duration(days: 7);
        break;
      case '1M':
        rangeDuration = const Duration(days: 30);
        break;
      case '3M':
        rangeDuration = const Duration(days: 90);
        break;
      case '6M':
        rangeDuration = const Duration(days: 180);
        break;
      case '1Y':
      default:
        rangeDuration = const Duration(days: 365);
        break;
    }

    final cutoff = now.subtract(rangeDuration);
    final filtered = full.where((p) => p.date.isAfter(cutoff)).toList();

    // 2. Data Grouping (Optimization for Performance)
    // If we have too many points, the chart lags. We group by week for > 60 days.
    if (filtered.length > 60) {
      _chartPoints = _groupByWeek(filtered);
    } else {
      _chartPoints = filtered;
    }

    // 3. Calculate Scale
    if (_chartPoints.isNotEmpty) {
      final maxUsage = _chartPoints
          .map((e) => e.usage.inMinutes.toDouble())
          .reduce(max);
      _maxY = maxUsage * 1.2; // 20% buffer
      if (_maxY < 60) _maxY = 60; // Min 1 hour scale
    } else {
      _maxY = 60;
    }
  }

  List<AppUsagePoint> _groupByWeek(List<AppUsagePoint> points) {
    if (points.isEmpty) return [];

    // Sort just in case
    // points.sort((a, b) => a.date.compareTo(b.date)); // Assume already sorted

    final grouped = <AppUsagePoint>[];
    // Efficient single pass:
    int i = 0;
    const int groupSize = 7;

    while (i < points.length) {
      int count = 0;
      int sumMinutes = 0;
      DateTime? firstDate;

      while (i < points.length && count < groupSize) {
        if (firstDate == null) firstDate = points[i].date;
        sumMinutes += points[i].usage.inMinutes;
        count++;
        i++;
      }

      if (count > 0 && firstDate != null) {
        // Average daily usage for this week
        final avg = sumMinutes ~/ count;
        grouped.add(
          AppUsagePoint(
            date: firstDate,
            usage: Duration(minutes: avg),
          ),
        );
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_chartPoints.isEmpty) {
      return const Center(child: Text("No data for period"));
    }

    // Calculate focused value (Header)
    AppUsagePoint focusedPoint;
    if (_touchedIndex != null &&
        _touchedIndex! >= 0 &&
        _touchedIndex! < _chartPoints.length) {
      focusedPoint = _chartPoints[_touchedIndex!];
    } else {
      // Default: Average of displayed period
      final totalMins = _chartPoints.fold(
        0,
        (sum, p) => sum + p.usage.inMinutes,
      );
      final avg = _chartPoints.isNotEmpty
          ? totalMins ~/ _chartPoints.length
          : 0;
      focusedPoint = AppUsagePoint(
        date: DateTime.now(),
        usage: Duration(minutes: avg),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(focusedPoint, _touchedIndex != null),
        const SizedBox(height: 24),
        Expanded(child: _buildChart()),
        const SizedBox(height: 16),
        _buildTimeSelector(),
      ],
    );
  }

  Widget _buildHeader(AppUsagePoint point, bool isHovering) {
    final theme = widget.theme;
    final mins = point.usage.inMinutes;

    String timeStr;
    if (mins >= 60) {
      timeStr = "${(mins / 60).toStringAsFixed(1)}h";
    } else {
      timeStr = "${mins}m";
    }

    String label = isHovering ? "Usage on this day" : "Daily Average";
    if (_selectedRange == '6M' || _selectedRange == '1Y') {
      if (isHovering) label = "Avg Usage (Week)";
    }

    String dateStr = isHovering
        ? DateFormat('MMM d').format(point.date)
        : "Past $_selectedRange";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeStr,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final theme = widget.theme;

    // Create rich gradient
    final gradientColors = [
      theme.colorScheme.primary.withOpacity(0.4),
      theme.colorScheme.primary.withOpacity(0.0),
    ];

    final lineGradient = LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),

        minX: 0,
        maxX: _chartPoints.length.toDouble() - 1,
        minY: 0,
        maxY: _maxY,

        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (spots) => spots.map((_) => null).toList(),
          ),
          touchCallback: (event, response) {
            if (response != null &&
                response.lineBarSpots != null &&
                event is! FlPanEndEvent &&
                event is! FlTapUpEvent) {
              setState(() {
                _touchedIndex = response.lineBarSpots!.first.spotIndex;
              });
            } else {
              setState(() {
                _touchedIndex = null;
              });
            }
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  strokeWidth: 1,
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 6,
                        color: theme.colorScheme.surface,
                        strokeWidth: 3,
                        strokeColor: theme.colorScheme.primary,
                      ),
                ),
              );
            }).toList();
          },
        ),

        lineBarsData: [
          LineChartBarData(
            spots: _chartPoints.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                e.value.usage.inMinutes.toDouble(),
              );
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            gradient: lineGradient,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300), // Smooth animation
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildTimeSelector() {
    final ranges = ['1W', '1M', '3M', '6M', '1Y'];
    final theme = widget.theme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ranges.map((r) {
        final isSelected = _selectedRange == r;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRange = r;
              _processData();
              _touchedIndex = null;
            });
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Text(
              r,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
