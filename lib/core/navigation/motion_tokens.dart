import 'package:flutter/material.dart';

class MotionTokens {
  MotionTokens._();

  static const Duration pageTransition = Duration(milliseconds: 350);

  static const Duration pageTransitionReverse = Duration(milliseconds: 300);

  static const Duration bottomSheet = Duration(milliseconds: 340);

  static const Duration dialog = Duration(milliseconds: 280);

  static const Duration fullscreenOverlay = Duration(milliseconds: 380);

  static const Duration bubbleReveal = Duration(milliseconds: 650);

  static const Duration micro = Duration(milliseconds: 120);

  static const Duration hero = Duration(milliseconds: 300);

  static const Curve pageEnter = _AppleEaseOut();

  static const Curve bubbleRevealCurve = Cubic(0.2, 1.0, 0.2, 1.0);

  static const Curve pageExit = Curves.easeIn;

  static const Curve settle = Curves.easeOutQuint;

  static const Curve overshoot = _SoftOvershoot();

  static const Curve decelerate = Curves.easeOutCubic;

  static const Curve accelerate = Curves.easeInQuad;

  static const double parallaxOffset = 0.3;

  static const double backgroundScale = 0.94;

  static const double foregroundStartScale = 0.985;

  static const double backgroundDesaturation = 0.15;

  static const double backgroundDimOpacity = 0.35;

  static const double cardBorderRadius = 20.0;

  static const double pageElevation = 16.0;

  static const double shadowOpacity = 0.18;

  static const double verticalParallax = 3.0;

  static const double opacityCompletionPoint = 0.35;

  static const double modalStartScale = 0.92;

  static const int backgroundDimDelayMs = 15;

  static SpringDescription get pageSpring =>
      const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 30.0);
}

class _AppleEaseOut extends Curve {
  const _AppleEaseOut();

  @override
  double transformInternal(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
  }
}

class _SoftOvershoot extends Curve {
  const _SoftOvershoot();

  @override
  double transformInternal(double t) {
    const overshoot = 0.03;
    if (t < 0.7) {
      final progress = t / 0.7;
      return progress * progress * (1.0 + overshoot);
    } else {
      final settleProgress = (t - 0.7) / 0.3;
      return (1.0 + overshoot) - (overshoot * settleProgress);
    }
  }
}
