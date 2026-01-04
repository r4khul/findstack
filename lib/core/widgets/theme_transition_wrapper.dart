import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A wrapper that facilitates a smooth circular reveal animation when switching themes.
///
/// This widget should be placed in the [MaterialApp.builder] property.
/// It works by:
/// 1. Capturing a screenshot of the current UI (old theme).
/// 2. Switching the theme (which rebuilds the app with the new theme).
/// 3. Overlaying the screenshot on top of the new theme.
/// 4. Animating a circular clip (hole) in the screenshot to reveal the new theme underneath.
///
/// NOTE: For unified jank masking across themes and navigation,
/// consider using [JankMaskingWrapper] instead.
class ThemeTransitionWrapper extends StatefulWidget {
  final Widget child;

  const ThemeTransitionWrapper({super.key, required this.child});

  static ThemeTransitionWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<ThemeTransitionWrapperState>()!;
  }

  @override
  State<ThemeTransitionWrapper> createState() => ThemeTransitionWrapperState();
}

class ThemeTransitionWrapperState extends State<ThemeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();

  ui.Image? _screenshot;
  Offset? _center;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _screenshot?.dispose();
        _screenshot = null;
        _center = null;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _screenshot?.dispose();
    super.dispose();
  }

  /// Triggers the theme switch animation.
  Future<void> switchTheme({
    required Offset center,
    required VoidCallback onThemeSwitch,
  }) async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary != null && boundary.debugNeedsPaint == false) {
      final deviceRatio = View.of(context).devicePixelRatio;
      final pixelRatio = deviceRatio > 1.5 ? 1.5 : deviceRatio;

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      setState(() {
        _screenshot = image;
        _center = center;
      });

      onThemeSwitch();

      _controller.forward(from: 0.0);
    } else {
      onThemeSwitch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(key: _repaintKey, child: widget.child);

    if (_screenshot == null || _center == null || !_controller.isAnimating) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: CustomPaint(
            painter: _ClipRevealPainter(
              image: _screenshot!,
              center: _center!,
              percent: _controller.value,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClipRevealPainter extends CustomPainter {
  final ui.Image image;
  final Offset center;
  final double percent;

  static final Paint _paint = Paint();

  _ClipRevealPainter({
    required this.image,
    required this.center,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxW = size.width;
    final maxH = size.height;

    final dX = center.dx > maxW / 2 ? center.dx : maxW - center.dx;
    final dY = center.dy > maxH / 2 ? center.dy : maxH - center.dy;

    final maxRadius = (dX * dX + dY * dY).toDouble() + 50;

    // Liquid curve
    final curvedPercent = _liquidCurve(percent);
    final radius = math.sqrt(maxRadius) * curvedPercent;

    final rect = Rect.fromLTWH(0, 0, maxW, maxH);

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(path);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      _paint,
    );

    canvas.restore();
  }

  double _liquidCurve(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
  }

  @override
  bool shouldRepaint(covariant _ClipRevealPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
