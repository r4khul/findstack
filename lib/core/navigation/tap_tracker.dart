import 'package:flutter/material.dart';

/// A global utility to track the last tap position.
/// This allows navigation transitions to originate from the user's point of contact
/// without having to pass the position manually through every callback.
class TapTracker {
  TapTracker._();

  static Offset _lastTapPosition = Offset.zero;

  /// The coordinates of the last user interaction.
  static Offset get lastTapPosition => _lastTapPosition;

  /// Updates the last tap position. Usually called by a global Listener.
  static void update(Offset position) {
    _lastTapPosition = position;
  }
}

/// A wrapper widget that listens for all pointer down events to track the tap position.
/// Place this at the root of your app (e.g., in your App widget).
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
