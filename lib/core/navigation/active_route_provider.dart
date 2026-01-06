import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that holds the name of the currently active route.
class ActiveRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? routeName) {
    state = routeName;
  }
}

/// Provider that holds the name of the currently active route.
final activeRouteProvider = NotifierProvider<ActiveRouteNotifier, String?>(
  ActiveRouteNotifier.new,
);
