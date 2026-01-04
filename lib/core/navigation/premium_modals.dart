import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion_tokens.dart';

/// Apple-grade modal system.
///
/// Principles:
/// - Modals feel lifted, not slid in
/// - Soft overshoot, gentle settle
/// - Background dims with slight lag
/// - All motion is interruptible
class PremiumModals {
  PremiumModals._();

  // ============================================================
  // BOTTOM SHEET - Lifted from surface
  // ============================================================

  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    bool useBlur = true,
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
    Color? backgroundColor,
  }) {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // We handle dimming ourselves
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: MotionTokens.bottomSheet,
      ),
      builder: (context) {
        return _BottomSheetWrapper(
          builder: builder,
          useBlur: useBlur,
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
        );
      },
    );
  }

  static Future<T?> showScrollableBottomSheet<T>({
    required BuildContext context,
    required ScrollableWidgetBuilder builder,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: MotionTokens.bottomSheet,
      ),
      builder: (context) {
        return _ScrollableBottomSheet(
          builder: builder,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
        );
      },
    );
  }

  // ============================================================
  // DIALOG - Lifted with soft overshoot
  // ============================================================

  static Future<T?> showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool useBlur = true,
  }) {
    HapticFeedback.selectionClick();

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent, // We animate this
      barrierLabel: 'Dismiss',
      transitionDuration: MotionTokens.dialog,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _DialogWrapper(
          animation: animation,
          useBlur: useBlur,
          builder: builder,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child; // Transition handled in _DialogWrapper
      },
    );
  }

  // ============================================================
  // FULL SCREEN OVERLAY
  // ============================================================

  static Future<T?> showFullScreenOverlay<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      barrierLabel: 'Dismiss',
      transitionDuration: MotionTokens.fullscreenOverlay,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _FullScreenWrapper(animation: animation, builder: builder);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Bottom sheet with lagged dim and lift animation
class _BottomSheetWrapper extends StatefulWidget {
  final WidgetBuilder builder;
  final bool useBlur;
  final Color backgroundColor;
  final double? initialChildSize;
  final double? minChildSize;
  final double? maxChildSize;

  const _BottomSheetWrapper({
    required this.builder,
    required this.useBlur,
    required this.backgroundColor,
    this.initialChildSize,
    this.minChildSize,
    this.maxChildSize,
  });

  @override
  State<_BottomSheetWrapper> createState() => _BottomSheetWrapperState();
}

class _BottomSheetWrapperState extends State<_BottomSheetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _dimController;

  @override
  void initState() {
    super.initState();
    // Dim animation lags behind modal by ~15ms
    _dimController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            MotionTokens.bottomSheet.inMilliseconds +
            MotionTokens.backgroundDimDelayMs,
      ),
    );

    // Start dim slightly delayed
    Future.delayed(
      Duration(milliseconds: MotionTokens.backgroundDimDelayMs),
      () {
        if (mounted) _dimController.forward();
      },
    );
  }

  @override
  void dispose() {
    _dimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.builder(context);

    return AnimatedBuilder(
      animation: _dimController,
      builder: (context, _) {
        final dimValue = MotionTokens.settle.transform(_dimController.value);

        return Stack(
          children: [
            // Background dim with blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: widget.useBlur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 6 * dimValue,
                          sigmaY: 6 * dimValue,
                        ),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.4 * dimValue),
                        ),
                      )
                    : ColoredBox(
                        color: Colors.black.withValues(alpha: 0.5 * dimValue),
                      ),
              ),
            ),
            // Sheet content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSheet(content),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheet(Widget content) {
    if (widget.initialChildSize != null) {
      return DraggableScrollableSheet(
        initialChildSize: widget.initialChildSize!,
        minChildSize: widget.minChildSize ?? 0.25,
        maxChildSize: widget.maxChildSize ?? 0.9,
        builder: (context, scrollController) {
          return _SheetContainer(
            backgroundColor: widget.backgroundColor,
            child: Column(
              children: [
                _DragHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: content,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return _SheetContainer(
      backgroundColor: widget.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          Flexible(child: content),
        ],
      ),
    );
  }
}

/// Scrollable bottom sheet
class _ScrollableBottomSheet extends StatefulWidget {
  final ScrollableWidgetBuilder builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Color backgroundColor;

  const _ScrollableBottomSheet({
    required this.builder,
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.backgroundColor,
  });

  @override
  State<_ScrollableBottomSheet> createState() => _ScrollableBottomSheetState();
}

class _ScrollableBottomSheetState extends State<_ScrollableBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _dimController;

  @override
  void initState() {
    super.initState();
    _dimController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            MotionTokens.bottomSheet.inMilliseconds +
            MotionTokens.backgroundDimDelayMs,
      ),
    );

    Future.delayed(
      Duration(milliseconds: MotionTokens.backgroundDimDelayMs),
      () {
        if (mounted) _dimController.forward();
      },
    );
  }

  @override
  void dispose() {
    _dimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dimController,
      builder: (context, _) {
        final dimValue = MotionTokens.settle.transform(_dimController.value);

        return Stack(
          children: [
            // Background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 6 * dimValue,
                    sigmaY: 6 * dimValue,
                  ),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.4 * dimValue),
                  ),
                ),
              ),
            ),
            // Sheet
            DraggableScrollableSheet(
              initialChildSize: widget.initialChildSize,
              minChildSize: widget.minChildSize,
              maxChildSize: widget.maxChildSize,
              builder: (context, scrollController) {
                return _SheetContainer(
                  backgroundColor: widget.backgroundColor,
                  child: Column(
                    children: [
                      _DragHandle(),
                      Expanded(
                        child: widget.builder(context, scrollController),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Dialog with lagged dim and soft overshoot
class _DialogWrapper extends StatefulWidget {
  final Animation<double> animation;
  final bool useBlur;
  final WidgetBuilder builder;

  const _DialogWrapper({
    required this.animation,
    required this.useBlur,
    required this.builder,
  });

  @override
  State<_DialogWrapper> createState() => _DialogWrapperState();
}

class _DialogWrapperState extends State<_DialogWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _dimController;

  @override
  void initState() {
    super.initState();
    _dimController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            MotionTokens.dialog.inMilliseconds +
            MotionTokens.backgroundDimDelayMs,
      ),
    );

    Future.delayed(
      Duration(milliseconds: MotionTokens.backgroundDimDelayMs),
      () {
        if (mounted) _dimController.forward();
      },
    );

    // Sync with route animation for dismissal
    widget.animation.addStatusListener((status) {
      if (status == AnimationStatus.reverse) {
        _dimController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _dimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _dimController]),
      builder: (context, _) {
        // Dialog scale with soft overshoot
        final scaleValue = MotionTokens.overshoot.transform(
          widget.animation.value,
        );
        final scale =
            MotionTokens.modalStartScale +
            ((1.0 - MotionTokens.modalStartScale) * scaleValue);

        // Early opacity
        final opacityProgress = (widget.animation.value / 0.4).clamp(0.0, 1.0);

        // Lagged dim
        final dimValue = MotionTokens.settle.transform(_dimController.value);

        return Stack(
          children: [
            // Background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: widget.useBlur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8 * dimValue,
                          sigmaY: 8 * dimValue,
                        ),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.5 * dimValue),
                        ),
                      )
                    : ColoredBox(
                        color: Colors.black.withValues(alpha: 0.6 * dimValue),
                      ),
              ),
            ),
            // Dialog
            Center(
              child: Opacity(
                opacity: opacityProgress,
                child: Transform.scale(
                  scale: scale,
                  child: RepaintBoundary(child: widget.builder(context)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Full screen overlay
class _FullScreenWrapper extends StatelessWidget {
  final Animation<double> animation;
  final WidgetBuilder builder;

  const _FullScreenWrapper({required this.animation, required this.builder});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = MotionTokens.settle.transform(animation.value);

        // Early opacity
        final opacityProgress = (animation.value / 0.3).clamp(0.0, 1.0);

        // Slide up
        final offset = Offset(0, (1.0 - value) * 0.15);

        return Stack(
          children: [
            // Background
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.85 * value),
              ),
            ),
            // Content
            Positioned.fill(
              child: Opacity(
                opacity: opacityProgress,
                child: FractionalTranslation(
                  translation: offset,
                  child: RepaintBoundary(child: builder(context)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sheet container with rounded corners
class _SheetContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const _SheetContainer({required this.child, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MotionTokens.cardBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Drag handle
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

typedef ScrollableWidgetBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);
