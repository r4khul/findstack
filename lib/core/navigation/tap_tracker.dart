import 'package:flutter/material.dart';

class TapTracker {
  TapTracker._();

  static Offset _lastTapPosition = Offset.zero;

  static Offset get lastTapPosition => _lastTapPosition;

  static void update(Offset position) {
    _lastTapPosition = position;
  }
}

class TapPositionProvider extends StatelessWidget {
  final Widget child;

  const TapPositionProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        TapTracker.update(event.position);
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
