import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// A premium circular reveal page route that originates from a specific tap position.
///
/// This route is designed to mask jank by using a smooth, GPU-accelerated
/// circular clip that expands from the user's point of interaction.
class BubbleRevealPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? tapPosition;
  final Duration? customDuration;

  BubbleRevealPageRoute({
    required this.page,
    this.tapPosition,
    this.customDuration,
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: customDuration ?? MotionTokens.bubbleReveal,
         reverseTransitionDuration:
             customDuration ?? MotionTokens.pageTransitionReverse,
         opaque: true,
         barrierColor: null,
         barrierLabel: null,
         maintainState: true,
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Determine the center of the reveal. Default to screen center if no tap position.
    final size = MediaQuery.of(context).size;
    final center = tapPosition ?? Offset(size.width / 2, size.height / 2);

    return _BubbleRevealTransition(
      primaryAnimation: animation,
      secondaryAnimation: secondaryAnimation,
      center: center,
      child: RepaintBoundary(child: child),
    );
  }
}

class _BubbleRevealTransition extends AnimatedWidget {
  final Animation<double> primaryAnimation;
  final Animation<double> secondaryAnimation;
  final Offset center;
  final Widget child;

  _BubbleRevealTransition({
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.center,
    required this.child,
  }) : super(
         listenable: Listenable.merge([primaryAnimation, secondaryAnimation]),
       );

  @override
  Widget build(BuildContext context) {
    // ====== BACKGROUND PAGE (being pushed over) ======
    if (secondaryAnimation.value > 0.001) {
      final secValue = MotionTokens.pageEnter.transform(
        secondaryAnimation.value,
      );
      final scale = 1.0 - (secValue * 0.05); // Slight scale down
      final dim = secValue * 0.3; // Subtle dim

      return Transform.scale(
        scale: scale,
        child: Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(dim)),
              ),
            ),
          ],
        ),
      );
    }

    // ====== ENTERING PAGE ======
    // Use the dramatic bubble reveal curve
    final value = MotionTokens.bubbleRevealCurve.transform(
      primaryAnimation.value,
    );

    // Optimize: If animation is complete, don't clip.
    // This removes the clipping layer as soon as it's not needed, improving performance.
    if (primaryAnimation.isCompleted) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        // Calculate the maximum radius required to cover the whole screen.
        final maxRadius = _calcMaxRadius(size, center);
        final currentRadius = maxRadius * value;

        return Stack(
          children: [
            // The expanding page
            CustomDisplayListClip(
              center: center,
              radius: currentRadius,
              child: Opacity(
                opacity: (value / 0.25).clamp(0.0, 1.0), // Fast intro
                child: Transform.scale(
                  scale: 0.94 + (0.06 * value),
                  child: child,
                ),
              ),
            ),

            // THE WOW FACTOR: A subtle leading edge ring/glow
            if (primaryAnimation.value > 0.01 && primaryAnimation.value < 0.99)
              IgnorePointer(
                child: CustomPaint(
                  size: size,
                  painter: _BubbleRingPainter(
                    center: center,
                    radius: currentRadius,
                    opacity: 1.0 - value, // Fade out as it expands
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _calcMaxRadius(Size size, Offset center) {
    // Distance to corners
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    double maxDist = 0;
    for (final corner in corners) {
      final dist = (center - corner).distance;
      if (dist > maxDist) maxDist = dist;
    }
    return maxDist;
  }
}

/// Paints a premium glow ring around the expanding bubble
class _BubbleRingPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;
  final Color color;

  _BubbleRingPainter({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);

    canvas.drawCircle(center, radius, paint);

    // Inner sharper ring
    final sharpPaint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, sharpPaint);
  }

  @override
  bool shouldRepaint(_BubbleRingPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.opacity != opacity;
}

/// A highly optimized clipping widget that uses [ClipPath] with [Path.addOval].
/// We wrap this in a [RepaintBoundary] to ensure the child isn't repainted
/// just because the clip radius changed.
class CustomDisplayListClip extends StatelessWidget {
  final Offset center;
  final double radius;
  final Widget child;

  const CustomDisplayListClip({
    super.key,
    required this.center,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CircularClipper(center: center, radius: radius),
      // CRITICAL: RepaintBoundary here ensures that the heavy child widget
      // subtree is only painted once and then cached as a layer.
      // The animation only re-applies the mask, which is a cheap GPU operation.
      child: RepaintBoundary(child: child),
    );
  }
}

class _CircularClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircularClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
