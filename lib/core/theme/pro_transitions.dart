import 'package:flutter/material.dart';
import '../navigation/motion_tokens.dart';

class ProPageTransitionsBuilder extends PageTransitionsBuilder {
  const ProPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool isVertical = route.fullscreenDialog;

    return _ProPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      isVertical: isVertical,
      child: child,
    );
  }
}

class _ProPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final bool isVertical;

  const _ProPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    final Widget optimizedChild = RepaintBoundary(child: child);

    final bool isBackground = secondaryAnimation.value > 0.001;
    final bool isEntering = animation.value < 0.999;

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: optimizedChild,
      builder: (context, staticChild) {
        if (isBackground) {
          final value = MotionTokens.pageEnter.transform(
            secondaryAnimation.value,
          );

          final slideX = -size.width * MotionTokens.parallaxOffset * value;

          final scale = 1.0 - (value * (1.0 - MotionTokens.backgroundScale));

          final dim = value * MotionTokens.backgroundDimOpacity;

          final radius = MotionTokens.cardBorderRadius * value;

          return Transform(
            transform: Matrix4.identity()
              ..translate(slideX, 0.0)
              ..scale(scale),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _desaturate(value * MotionTokens.backgroundDesaturation),
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    staticChild!,
                    if (dim > 0.01)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: dim),
                              borderRadius: BorderRadius.circular(radius),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        if (isEntering) {
          final value = MotionTokens.pageEnter.transform(animation.value);

          final opacityProgress =
              (animation.value / MotionTokens.opacityCompletionPoint).clamp(
                0.0,
                1.0,
              );
          final opacity = Curves.easeOut.transform(opacityProgress);

          final slideX = isVertical ? 0.0 : size.width * (1.0 - value);
          final slideY = isVertical
              ? size.height * (1.0 - value)
              : MotionTokens.verticalParallax * (1.0 - value);

          final scale =
              MotionTokens.foregroundStartScale +
              ((1.0 - MotionTokens.foregroundStartScale) * value);

          final elevation = MotionTokens.pageElevation * value;

          return Opacity(
            opacity: opacity,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(slideX, slideY)
                ..scale(scale),
              alignment: isVertical
                  ? Alignment.topCenter
                  : Alignment.centerLeft,
              child: PhysicalModel(
                elevation: elevation,
                color: theme.scaffoldBackgroundColor,
                shadowColor: Colors.black.withValues(
                  alpha: MotionTokens.shadowOpacity,
                ),
                child: staticChild,
              ),
            ),
          );
        }

        return staticChild!;
      },
    );
  }

  List<double> _desaturate(double amount) {
    final s = 1.0 - amount;
    return [
      0.2126 + 0.7874 * s,
      0.7152 - 0.7152 * s,
      0.0722 - 0.0722 * s,
      0,
      0,
      0.2126 - 0.2126 * s,
      0.7152 + 0.2848 * s,
      0.0722 - 0.0722 * s,
      0,
      0,
      0.2126 - 0.2126 * s,
      0.7152 - 0.7152 * s,
      0.0722 + 0.9278 * s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

@Deprecated('Use PremiumModals.showDialog instead')
Future<T?> showProDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.6),
    barrierLabel: 'Dismiss',
    transitionDuration: MotionTokens.dialog,
    pageBuilder: (context, anim, secAnim) {
      return RepaintBoundary(child: builder(context));
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final value = MotionTokens.overshoot.transform(animation.value);
      final scale =
          MotionTokens.modalStartScale +
          ((1.0 - MotionTokens.modalStartScale) * value);
      final opacity = (animation.value / 0.4).clamp(0.0, 1.0);

      return Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: child),
      );
    },
  );
}
