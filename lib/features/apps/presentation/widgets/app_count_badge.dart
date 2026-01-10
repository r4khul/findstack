import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AppCountOverlay extends StatefulWidget {
  final Widget child;
  final int count;
  final Duration debounceDuration;

  const AppCountOverlay({
    super.key,
    required this.child,
    required this.count,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AppCountOverlay> createState() => _AppCountOverlayState();
}

class _AppCountOverlayState extends State<AppCountOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _scrollEndTimer;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLogicallyVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
    );

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuad,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _hide() {
    if (_isLogicallyVisible) {
      _isLogicallyVisible = false;
      _controller.reverse();
    }
    _scrollEndTimer?.cancel();
  }

  void _show() {
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(widget.debounceDuration, () {
      if (mounted && !_isLogicallyVisible) {
        _isLogicallyVisible = true;
        _controller.forward();
      }
    });
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) return;

    if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        _hide();
      } else {
        _show();
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta != null &&
          notification.scrollDelta!.abs() > 0.5) {
        _hide();
        _show();
      }
    } else if (notification is ScrollEndNotification) {
      _show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return false;
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,

          Align(
            alignment: Alignment.centerLeft,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final val = _controller.value;
                  if (val == 0.0) return const SizedBox.shrink();

                  return Transform.translate(
                    offset: Offset(_slideAnimation.value, 0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: IgnorePointer(
                        ignoring:
                            val <
                            0.1,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _VerticalBadgeContent(count: widget.count),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalBadgeContent extends StatelessWidget {
  final int count;

  const _VerticalBadgeContent({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutExpo,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.6),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  right: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            "$count",
                            key: ValueKey<int>(count),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Apps",
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
