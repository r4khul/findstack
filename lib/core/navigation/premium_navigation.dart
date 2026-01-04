import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'tap_tracker.dart';

/// A "God-Mode" navigation utility that masks jank using a high-performance
/// screenshot overlay technique.
class PremiumNavigation {
  PremiumNavigation._();

  static final GlobalKey rootBoundaryKey = GlobalKey();

  /// 3-PHASE LIQUID TRANSITION
  static Future<void> push(
    BuildContext context,
    Widget page, {
    Color? overrideColor,
  }) async {
    // Capture state synchronously
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    // COLOR LOGIC: Pure Black for Dark Mode, Scaffold White for Light Mode
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor =
        overrideColor ??
        (isDark ? const Color(0xFF000000) : theme.scaffoldBackgroundColor);

    debugPrint("[PremiumNavigation] 🔵 Start Push: $page");

    // ---------------------------------------------------------
    // PHASE 1: FREEZE (Capture Screenshot)
    // ---------------------------------------------------------
    final capturedImage = await _captureScreenshot(pixelRatio);

    if (capturedImage == null ||
        capturedImage.width == 0 ||
        capturedImage.height == 0) {
      debugPrint("[PremiumNavigation] ⚠️ Screenshot failed. Fallback.");
      navigator.push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: Duration.zero,
        ),
      );
      return;
    }

    // ---------------------------------------------------------
    // PREPARE OVERLAY
    // ---------------------------------------------------------
    final overlayState = Overlay.of(context, rootOverlay: true);
    final animationCompleter = Completer<void>();
    final fadeNotifier = ValueNotifier<bool>(
      false,
    ); // Signal for Phase 3 (Fade)
    late OverlayEntry entry;
    bool overlayInserted = false;

    try {
      entry = OverlayEntry(
        builder: (context) => _LiquidTransitionOverlay(
          image: capturedImage,
          color: bubbleColor,
          tapPosition: TapTracker.lastTapPosition,
          fadeNotifier: fadeNotifier,
          onAnimationComplete: () {
            if (!animationCompleter.isCompleted) animationCompleter.complete();
          },
        ),
      );

      overlayState.insert(entry);
      overlayInserted = true;
      debugPrint("[PremiumNavigation] ❄️ UI Frozen");
      HapticFeedback.lightImpact();

      // ---------------------------------------------------------
      // PHASE 1 CONT: LIQUID EXPANSION
      // ---------------------------------------------------------
      await animationCompleter.future;

      // ---------------------------------------------------------
      // PHASE 2: SWAP (Navigation)
      // ---------------------------------------------------------
      debugPrint("[PremiumNavigation] 🔄 Swapping Route...");

      // Push new page behind the opaque overlay
      navigator.push(
        PageRouteBuilder(
          pageBuilder: (context, _, __) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      // ---------------------------------------------------------
      // PHASE 3: GRACEFUL REVEAL (Fade Out Overlay)
      // ---------------------------------------------------------
      // 1. Wait for first frame of new page
      await Future.delayed(const Duration(milliseconds: 60));

      // 2. Trigger Fade Out
      debugPrint("[PremiumNavigation] 🌫️ Fading Out Overlay...");
      fadeNotifier.value = true;

      // 3. Wait for fade animation (300ms matches the controller)
      await Future.delayed(const Duration(milliseconds: 320));

      if (overlayInserted) {
        entry.remove();
        overlayInserted = false;
        debugPrint("[PremiumNavigation] ✨ Transition Complete");
      }
    } catch (e, stack) {
      debugPrint("[PremiumNavigation] 🛑 CRITICAL ERROR: $e");
      if (overlayInserted) {
        entry.remove();
      }
      // Attempt fallback
      try {
        navigator.push(MaterialPageRoute(builder: (_) => page));
      } catch (_) {}
    }
  }

  static Future<ui.Image?> _captureScreenshot(double devicePixelRatio) async {
    try {
      final boundary =
          rootBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Cap at 1.0x for max performance
      final safeRatio = math.min(devicePixelRatio, 1.0);
      return await boundary.toImage(pixelRatio: safeRatio);
    } catch (e) {
      return null;
    }
  }
}

/// The visual component of the transition.
class _LiquidTransitionOverlay extends StatefulWidget {
  final ui.Image image;
  final Color color;
  final Offset tapPosition;
  final VoidCallback onAnimationComplete;
  final ValueNotifier<bool> fadeNotifier;

  const _LiquidTransitionOverlay({
    required this.image,
    required this.color,
    required this.tapPosition,
    required this.onAnimationComplete,
    required this.fadeNotifier,
  });

  @override
  State<_LiquidTransitionOverlay> createState() =>
      _LiquidTransitionOverlayState();
}

class _LiquidTransitionOverlayState extends State<_LiquidTransitionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _liquidController;
  late Animation<double> _liquidAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // LIQUID: 450ms for snappy but fluid expansion
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _liquidAnimation = CurvedAnimation(
      parent: _liquidController,
      curve: Curves.easeInOutCubic, // Strong acceleration
    );

    // FADE: 300ms for silky smooth reveal
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start Liquid
    _liquidController.forward().then((_) {
      if (mounted) widget.onAnimationComplete();
    });

    // Listen for Fade Signal
    widget.fadeNotifier.addListener(_onFadeSignal);
  }

  void _onFadeSignal() {
    if (widget.fadeNotifier.value && mounted) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    widget.fadeNotifier.removeListener(_onFadeSignal);
    _liquidController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition is heavily optimized by Flutter (opacity layer)
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // LAYER 1: Frozen App State
          Positioned.fill(
            child: Container(
              color: widget.color.withOpacity(1.0), // Ensure solid background
              child: RawImage(image: widget.image, fit: BoxFit.cover),
            ),
          ),

          // LAYER 2: Liquid Expansion
          AnimatedBuilder(
            animation: _liquidAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _LiquidPainter(
                  progress: _liquidAnimation.value,
                  center: widget.tapPosition,
                  color: widget.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress;
  final Offset center;
  final Color color;

  _LiquidPainter({
    required this.progress,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Calculation optimized for speed
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) * 1.1;
    final currentRadius = maxRadius * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
