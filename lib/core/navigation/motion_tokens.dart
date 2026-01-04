import 'package:flutter/material.dart';

/// Apple-grade motion system.
///
/// Principles:
/// - Motion is continuous, never starts/stops
/// - Fast acceleration, long soft deceleration
/// - Surfaces move through space with momentum
/// - Animation completes just before user expects it
class MotionTokens {
  MotionTokens._();

  // ============================================================
  // DURATIONS - Short but never rushed
  // ============================================================

  /// Page transition - feels instantaneous yet smooth
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Reverse slightly faster - matches user's "going back" mental model
  static const Duration pageTransitionReverse = Duration(milliseconds: 300);

  /// Bottom sheet - fast lift, soft settle
  static const Duration bottomSheet = Duration(milliseconds: 340);

  /// Dialog - snappy appearance
  static const Duration dialog = Duration(milliseconds: 280);

  /// Fullscreen overlay
  static const Duration fullscreenOverlay = Duration(milliseconds: 380);

  /// Premium bubble reveal - longer for "wow" effect
  static const Duration bubbleReveal = Duration(milliseconds: 650);

  /// Micro-interactions
  static const Duration micro = Duration(milliseconds: 120);

  /// Hero animations
  static const Duration hero = Duration(milliseconds: 300);

  // ============================================================
  // CURVES - Asymmetric: fast attack, long decay
  // ============================================================

  /// Primary entrance curve - iOS spring-like
  /// Fast acceleration, long soft deceleration
  static const Curve pageEnter = _AppleEaseOut();

  /// Dramatic reveal curve - super fast start, then very soft settle
  static const Curve bubbleRevealCurve = Cubic(0.2, 1.0, 0.2, 1.0);

  /// Exit curve - quick response
  static const Curve pageExit = Curves.easeIn;

  /// Decelerate-heavy curve for settling motion
  static const Curve settle = Curves.easeOutQuint;

  /// Slight overshoot for "lifted" feel (modals)
  static const Curve overshoot = _SoftOvershoot();

  /// Standard deceleration
  static const Curve decelerate = Curves.easeOutCubic;

  /// Fast start for dismissals
  static const Curve accelerate = Curves.easeInQuad;

  // ============================================================
  // SPATIAL - Subtle depth perception
  // ============================================================

  /// Background parallax offset (fraction of width)
  static const double parallaxOffset = 0.3;

  /// Background scale during push (subtle depth)
  static const double backgroundScale = 0.94;

  /// Foreground starting scale (momentum feel)
  static const double foregroundStartScale = 0.985;

  /// Background contrast reduction
  static const double backgroundDesaturation = 0.15;

  /// Background dim opacity
  static const double backgroundDimOpacity = 0.35;

  /// Card border radius for depth effect
  static const double cardBorderRadius = 20.0;

  /// Page elevation
  static const double pageElevation = 16.0;

  /// Shadow opacity
  static const double shadowOpacity = 0.18;

  /// Vertical micro-parallax for page entry (pixels)
  static const double verticalParallax = 3.0;

  // ============================================================
  // OPACITY - Early ramp to mask first frame
  // ============================================================

  /// Opacity completes at this fraction of animation (0.35 = 35%)
  static const double opacityCompletionPoint = 0.35;

  // ============================================================
  // MODAL REFINEMENTS
  // ============================================================

  /// Modal starting scale
  static const double modalStartScale = 0.92;

  /// Background dim delay (ms) - lags behind modal
  static const int backgroundDimDelayMs = 15;

  // ============================================================
  // SPRING SIMULATION for interruptibility
  // ============================================================

  static SpringDescription get pageSpring =>
      const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 30.0);
}

/// Custom curve: fast attack, very long soft decay
/// Mimics iOS UISpringTimingParameters
class _AppleEaseOut extends Curve {
  const _AppleEaseOut();

  @override
  double transformInternal(double t) {
    // Attempt to emulate: t^0.4 for slow start, exponential decay
    // This creates fast initial movement, then long float to rest
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
  }
}

/// Soft overshoot - subtle lift without cartoon bounce
class _SoftOvershoot extends Curve {
  const _SoftOvershoot();

  @override
  double transformInternal(double t) {
    // Overshoot by ~3% then settle
    const overshoot = 0.03;
    if (t < 0.7) {
      // Fast approach to overshoot point
      final progress = t / 0.7;
      return progress * progress * (1.0 + overshoot);
    } else {
      // Gentle settle from overshoot to 1.0
      final settleProgress = (t - 0.7) / 0.3;
      return (1.0 + overshoot) - (overshoot * settleProgress);
    }
  }
}
