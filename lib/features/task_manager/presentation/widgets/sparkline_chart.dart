library;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A compact sparkline chart for visualizing process history.
/// Displays a smooth curved line with gradient fill.
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final Color lineColor;
  final Color? fillColor;
  final double lineWidth;

  const SparklineChart({
    super.key,
    required this.data,
    this.width = 70,
    this.height = 24,
    this.lineColor = const Color(0xFF4CAF50),
    this.fillColor,
    this.lineWidth = 1.5,
  });

  /// Create with intensity-based coloring
  factory SparklineChart.forIntensity({
    Key? key,
    required List<double> data,
    required int intensityLevel,
    double width = 70,
    double height = 24,
  }) {
    final color = _getColorForIntensity(intensityLevel);
    return SparklineChart(
      key: key,
      data: data,
      width: width,
      height: height,
      lineColor: color,
      fillColor: color.withOpacity(0.2),
    );
  }

  static Color _getColorForIntensity(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF4CAF50); // Idle - Green
      case 1:
        return const Color(0xFF8BC34A); // Low - Light Green
      case 2:
        return const Color(0xFFFFC107); // Moderate - Amber
      case 3:
        return const Color(0xFFFF9800); // High - Orange
      case 4:
        return const Color(0xFFF44336); // Critical - Red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If only 1 data point, create a flat line
    final displayData = data.length < 2
        ? (data.isEmpty ? [0.0, 0.0] : [data.first, data.first])
        : data;

    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _SparklinePainter(
            data: displayData,
            lineColor: lineColor,
            fillColor: fillColor,
            lineWidth: lineWidth,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color? fillColor;
  final double lineWidth;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    this.fillColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).clamp(1.0, 100.0);
    final minValue = data.reduce((a, b) => a < b ? a : b).clamp(0.0, 99.0);
    final range = (maxValue - minValue).clamp(1.0, 100.0);

    // Padding to avoid clipping
    const padding = 2.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // Build points
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * drawWidth;
      final normalized = (data[i] - minValue) / range;
      final y = padding + drawHeight - (normalized * drawHeight);
      points.add(Offset(x, y));
    }

    // Create smooth path using cubic bezier curves
    final path = _createSmoothPath(points);

    // Draw fill gradient
    if (fillColor != null) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final gradient = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [fillColor!, fillColor!.withOpacity(0)],
      );

      final fillPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw end dot
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(points.last, 2.5, dotPaint);
  }

  Path _createSmoothPath(List<Offset> points) {
    if (points.length < 2) return Path();

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Use cubic bezier curves for smoothing
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // Control points for smooth curve
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}
