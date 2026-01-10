import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingTechIcons extends StatefulWidget {
  final bool isDark;
  final int pageIndex;

  const FloatingTechIcons({
    super.key,
    required this.isDark,
    this.pageIndex = 0,
  });

  @override
  State<FloatingTechIcons> createState() => _FloatingTechIconsState();
}

class _FloatingTechIconsState extends State<FloatingTechIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageIndex != 0) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildIcon(
              asset: 'assets/vectors/icon_flutter.svg',
              size: 52,
              rotation: -15,
              left: -26,
              top: size.height * 0.16,
              delay: 0.0,
            ),

            _buildIcon(
              asset: 'assets/vectors/icon_android.svg',
              size: 40,
              rotation: 12,
              left: -20,
              top: size.height * 0.48,
              delay: 0.15,
            ),

            _buildIcon(
              asset: 'assets/vectors/icon_kotlin.svg',
              size: 28,
              rotation: 20,
              right: 28,
              top: size.height * 0.10,
              delay: 0.25,
            ),

            _buildIcon(
              asset: 'assets/vectors/icon_reactnative.svg',
              size: 36,
              rotation: -8,
              right: 24,
              bottom: size.height * 0.30,
              delay: 0.35,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon({
    required String asset,
    required double size,
    required double rotation,
    required double delay,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    final slideAnimation =
        Tween<Offset>(
          begin: Offset(left != null ? -0.5 : 0.5, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
          ),
        );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      ),
    );

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Transform.rotate(
            angle: rotation * math.pi / 180,
            child: Opacity(
              opacity: 0.35,
              child: SvgPicture.asset(
                asset,
                width: size,
                height: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
