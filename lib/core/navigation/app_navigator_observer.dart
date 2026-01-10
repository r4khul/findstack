import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'active_route_provider.dart';

class AppNavigatorObserver extends NavigatorObserver {
  final WidgetRef? ref;

  final bool enableLogging;

  AppNavigatorObserver({this.ref, this.enableLogging = kDebugMode});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log('PUSH', route, previousRoute);
    _updateActiveRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _log('POP', route, previousRoute);
    if (previousRoute != null) {
      _updateActiveRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (enableLogging) {
      debugPrint(
        '📍 REPLACE: ${oldRoute?.settings.name ?? "unknown"} → '
        '${newRoute?.settings.name ?? "unknown"}',
      );
    }
    if (newRoute != null) {
      _updateActiveRoute(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _log('REMOVE', route, previousRoute);
    if (previousRoute != null) {
      _updateActiveRoute(previousRoute);
    }
  }

  void _updateActiveRoute(Route<dynamic> route) {
    if (ref != null) {
      Future.microtask(() {
        final name = route.settings.name;
        ref!.read(activeRouteProvider.notifier).update(name);
      });
    }
  }

  void _log(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (!enableLogging) return;

    final routeName = route.settings.name ?? route.runtimeType.toString();
    final previousName = previousRoute?.settings.name ?? 'none';

    final emoji = switch (action) {
      'PUSH' => '➡️',
      'POP' => '⬅️',
      'REMOVE' => '🗑️',
      _ => '📍',
    };

    debugPrint('$emoji $action: $routeName (from: $previousName)');
  }

  void onScreenView(String screenName) {
  }
}
