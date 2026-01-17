library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/process_provider.dart';

/// Compact, modern system overview card with monochromatic design.
class SystemOverviewCard extends ConsumerWidget {
  final double cpuPercentage;
  final int usedRamMb;
  final int totalRamMb;
  final int batteryLevel;
  final bool isCharging;
  final String deviceModel;
  final String androidVersion;

  const SystemOverviewCard({
    super.key,
    required this.cpuPercentage,
    required this.usedRamMb,
    required this.totalRamMb,
    required this.batteryLevel,
    required this.isCharging,
    required this.deviceModel,
    required this.androidVersion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final systemDetailsValues = ref.watch(systemDetailsProvider).asData?.value;

    final double cpuTemp = systemDetailsValues?.cpuTemp ?? 0.0;
    final String kernelVer = systemDetailsValues?.kernel ?? "...";
    final int cachedKb = systemDetailsValues?.cachedRealKb ?? 0;
    final int cachedMb = cachedKb ~/ 1024;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Compact Header
          _CompactHeader(
            deviceModel: deviceModel,
            androidVersion: androidVersion,
            kernelVersion: kernelVer,
            isCharging: isCharging,
            batteryLevel: batteryLevel,
          ),

          const SizedBox(height: 16),

          // Stats Row - CPU, RAM, Metrics inline
          Row(
            children: [
              // CPU Gauge
              _CompactCpuGauge(percentage: cpuPercentage),
              const SizedBox(width: 14),

              // RAM + Metrics
              Expanded(
                child: Column(
                  children: [
                    _CompactRamBar(
                      usedMb: usedRamMb,
                      totalMb: totalRamMb,
                      cachedMb: cachedMb,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            icon: Icons.thermostat_rounded,
                            value: cpuTemp > 0
                                ? "${cpuTemp.toStringAsFixed(0)}°"
                                : "--",
                            isWarning: cpuTemp > 45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniMetric(
                            icon: Icons.speed_rounded,
                            value: "${cpuPercentage.toStringAsFixed(0)}%",
                            label: "load",
                            isWarning: cpuPercentage > 70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniMetric(
                            icon: isCharging
                                ? Icons.bolt_rounded
                                : Icons.battery_std_rounded,
                            value: "$batteryLevel%",
                            isHighlighted: isCharging,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final String deviceModel;
  final String androidVersion;
  final String kernelVersion;
  final bool isCharging;
  final int batteryLevel;

  const _CompactHeader({
    required this.deviceModel,
    required this.androidVersion,
    required this.kernelVersion,
    required this.isCharging,
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Device Icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.smartphone_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),

        // Device Info - Expanded to prevent overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceModel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "$androidVersion • K${kernelVersion.split('-').first}",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Charging indicator (compact)
        if (isCharging)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  "$batteryLevel%",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompactCpuGauge extends StatelessWidget {
  final double percentage;

  const _CompactCpuGauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 64.0;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background
              CustomPaint(
                size: const Size(size, size),
                painter: _RingPainter(
                  percentage: 100,
                  color: theme.colorScheme.outline.withOpacity(0.12),
                  strokeWidth: 5,
                ),
              ),
              // Progress
              CustomPaint(
                size: const Size(size, size),
                painter: _RingPainter(
                  percentage: value,
                  color: theme.colorScheme.primary,
                  strokeWidth: 5,
                ),
              ),
              // Center
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'CPU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = (percentage / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percentage != percentage || old.color != color;
}

class _CompactRamBar extends StatelessWidget {
  final int usedMb;
  final int totalMb;
  final int cachedMb;

  const _CompactRamBar({
    required this.usedMb,
    required this.totalMb,
    required this.cachedMb,
  });

  double get percentage => totalMb > 0 ? (usedMb / totalMb * 100) : 0;

  String _formatMem(int mb) =>
      mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)}G' : '${mb}M';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'RAM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                if (cachedMb > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatMem(cachedMb)} cached',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${_formatMem(usedMb)} / ${_formatMem(totalMb)}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final bool isHighlighted;
  final bool isWarning;

  const _MiniMetric({
    required this.icon,
    required this.value,
    this.label,
    this.isHighlighted = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color accentColor;
    if (isWarning) {
      accentColor = theme.colorScheme.error;
    } else if (isHighlighted) {
      accentColor = theme.colorScheme.primary;
    } else {
      accentColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: isWarning ? accentColor : null,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
