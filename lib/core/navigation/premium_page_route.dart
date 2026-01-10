import 'package:flutter/material.dart';
import 'motion_tokens.dart';

enum TransitionType { slideRight, slideUp, fade, scale }

class PremiumPageRoute<T> extends PageRoute<T> {
  final Widget page;
  final TransitionType transitionType;
  @override
  final bool fullscreenDialog;

  PremiumPageRoute({
    required this.page,
    this.transitionType = TransitionType.slideRight,
    this.fullscreenDialog = false,
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => fullscreenDialog
      ? MotionTokens.fullscreenOverlay
      : MotionTokens.pageTransition;

  @override
  Duration get reverseTransitionDuration => MotionTokens.pageTransitionReverse;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return RepaintBoundary(child: page);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case TransitionType.slideUp:
        return _SlideUpTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      case TransitionType.fade:
        return _FadeTransition(animation: animation, child: child);
      case TransitionType.scale:
        return _ScaleTransition(animation: animation, child: child);
      case TransitionType.slideRight:
        return _SlideRightTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
    }
  }
}

class _SlideRightTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SlideRightTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, staticChild) {
        final primaryValue = MotionTokens.pageEnter.transform(
          animation.value.clamp(0.0, 1.0),
        );

        final secondaryValue = MotionTokens.pageEnter.transform(
          secondaryAnimation.value.clamp(0.0, 1.0),
        );

        final isBackground = secondaryAnimation.value > 0.001;

        final isEntering = animation.value < 0.999;

        if (isBackground) {
          final slideX =
              -size.width * MotionTokens.parallaxOffset * secondaryValue;

          final scale =
              1.0 - (secondaryValue * (1.0 - MotionTokens.backgroundScale));

          final dim = secondaryValue * MotionTokens.backgroundDimOpacity;

          final radius = MotionTokens.cardBorderRadius * secondaryValue;

          return Transform(
            transform: Matrix4.identity()
              ..translate(slideX, 0.0)
              ..scale(scale),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _desaturateMatrix(
                    secondaryValue * MotionTokens.backgroundDesaturation,
                  ),
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
          final opacityProgress =
              (animation.value / MotionTokens.opacityCompletionPoint).clamp(
                0.0,
                1.0,
              );
          final opacity = Curves.easeOut.transform(opacityProgress);

          final slideX = size.width * (1.0 - primaryValue);

          final scale =
              MotionTokens.foregroundStartScale +
              ((1.0 - MotionTokens.foregroundStartScale) * primaryValue);

          final slideY = MotionTokens.verticalParallax * (1.0 - primaryValue);

          final elevation = MotionTokens.pageElevation * primaryValue;

          return Opacity(
            opacity: opacity,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(slideX, slideY)
                ..scale(scale),
              alignment: Alignment.centerLeft,
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

  List<double> _desaturateMatrix(double amount) {
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

class _SlideUpTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SlideUpTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, staticChild) {
        final value = MotionTokens.settle.transform(animation.value);

        final opacityProgress =
            (animation.value / MotionTokens.opacityCompletionPoint).clamp(
              0.0,
              1.0,
            );
        final opacity = Curves.easeOut.transform(opacityProgress);

        final slideY = size.height * (1.0 - value);

        final scale = 0.98 + (0.02 * value);

        return Opacity(
          opacity: opacity,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(0.0, slideY)
              ..scale(scale),
            alignment: Alignment.topCenter,
            child: staticChild,
          ),
        );
      },
    );
  }
}

class _FadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, staticChild) {
        final value = MotionTokens.pageEnter.transform(animation.value);
        final scale = 0.96 + (0.04 * value);

        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: staticChild),
        );
      },
    );
  }
}

class _ScaleTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ScaleTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, staticChild) {
        final scaleValue = MotionTokens.overshoot.transform(animation.value);
        final scale =
            MotionTokens.modalStartScale +
            ((1.0 - MotionTokens.modalStartScale) * scaleValue);

        final opacityProgress = (animation.value / 0.4).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacityProgress,
          child: Transform.scale(scale: scale, child: staticChild),
        );
      },
    );
  }
}
