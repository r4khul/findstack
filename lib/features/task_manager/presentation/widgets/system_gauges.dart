library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Monochromatic circular CPU gauge with percentage display.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percentage: 100,
                  color: theme.colorScheme.outline.withOpacity(0.15),
                  strokeWidth: strokeWidth,
                ),
              ),
              // Foreground ring
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percentage: value,
                  color: theme.colorScheme.primary,
                  strokeWidth: strokeWidth,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      height: 1.0,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CPU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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

/// Monochromatic horizontal memory usage bar.
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
              color: theme.colorScheme.outline.withOpacity(0.15),
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
                    decoration: BoxDecoration(color: theme.colorScheme.primary),
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

/// Monochromatic temperature indicator badge.
class TemperatureBadge extends StatelessWidget {
  final double temperature;

  const TemperatureBadge({super.key, required this.temperature});

  bool get _isHot => temperature >= 45;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = _isHot
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: displayColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isHot
              ? _PulsingIcon(
                  icon: Icons.thermostat_rounded,
                  color: displayColor,
                )
              : Icon(Icons.thermostat_rounded, size: 18, color: displayColor),
          const SizedBox(width: 6),
          Text(
            '${temperature.round()}°C',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: displayColor,
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
