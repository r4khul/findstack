library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated circular CPU gauge with percentage display.
class CpuGauge extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;

  const CpuGauge({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 8,
  });

  Color get _gaugeColor {
    if (percentage < 25) return const Color(0xFF4CAF50);
    if (percentage < 50) return const Color(0xFFFFC107);
    if (percentage < 75) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percentage: 100,
                  color: theme.colorScheme.surfaceContainerHighest,
                  strokeWidth: strokeWidth,
                ),
              ),
              // Foreground ring
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percentage: value,
                  color: _gaugeColor,
                  strokeWidth: strokeWidth,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'CPU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
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

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  _GaugePainter({
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

    // Start from top (-90 degrees)
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
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

/// Animated horizontal memory usage bar.
class MemoryBar extends StatelessWidget {
  final int usedMb;
  final int totalMb;
  final double height;

  const MemoryBar({
    super.key,
    required this.usedMb,
    required this.totalMb,
    this.height = 12,
  });

  double get percentage => totalMb > 0 ? (usedMb / totalMb * 100) : 0;

  Color get _barColor {
    if (percentage < 50) return const Color(0xFF4CAF50);
    if (percentage < 75) return const Color(0xFFFFC107);
    if (percentage < 90) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _usedText {
    if (usedMb >= 1024) {
      return '${(usedMb / 1024).toStringAsFixed(1)}GB';
    }
    return '${usedMb}MB';
  }

  String get _totalText {
    if (totalMb >= 1024) {
      return '${(totalMb / 1024).toStringAsFixed(1)}GB';
    }
    return '${totalMb}MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RAM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$_usedText / $_totalText',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_barColor.withOpacity(0.8), _barColor],
                      ),
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

/// Temperature indicator with color-coded icon.
class TemperatureBadge extends StatelessWidget {
  final double temperature;

  const TemperatureBadge({super.key, required this.temperature});

  Color get _tempColor {
    if (temperature < 35) return const Color(0xFF4CAF50);
    if (temperature < 40) return const Color(0xFFFFC107);
    if (temperature < 45) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  bool get _isHot => temperature >= 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _tempColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tempColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isHot
              ? _PulsingIcon(icon: Icons.thermostat_rounded, color: _tempColor)
              : Icon(Icons.thermostat_rounded, size: 18, color: _tempColor),
          const SizedBox(width: 6),
          Text(
            '${temperature.round()}°C',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: _tempColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(widget.icon, size: 18, color: widget.color),
        );
      },
    );
  }
}
