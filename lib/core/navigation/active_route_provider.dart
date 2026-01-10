import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? routeName) {
    state = routeName;
  }
}

final activeRouteProvider = NotifierProvider<ActiveRouteNotifier, String?>(
  ActiveRouteNotifier.new,
);
