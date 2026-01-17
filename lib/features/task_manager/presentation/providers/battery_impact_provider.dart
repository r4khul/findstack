library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/battery_impact.dart';

const _channel = MethodChannel('com.rakhul.unfilter/apps');
const _fetchTimeout = Duration(seconds: 15);
const _refreshInterval = Duration(
  minutes: 5,
); // Battery data doesn't change rapidly

List<AppBatteryImpact> _parseBatteryImpactData(dynamic result) {
  if (result is List) {
    return result.map((e) => AppBatteryImpact.fromMap(e as Map)).toList();
  }
  return [];
}

List<DailyBatteryUsage> _parseBatteryHistory(dynamic result) {
  if (result is List) {
    return result.map((e) => DailyBatteryUsage.fromMap(e as Map)).toList();
  }
  return [];
}

Future<List<AppBatteryImpact>> _fetchBatteryImpactData({
  int hoursBack = 24,
}) async {
  try {
    final result = await _channel
        .invokeMethod('getBatteryImpactData', {'hoursBack': hoursBack})
        .timeout(_fetchTimeout);
    return await compute(_parseBatteryImpactData, result);
  } on TimeoutException {
    debugPrint('Battery impact fetch timed out');
    return [];
  } catch (e) {
    debugPrint('Error fetching battery impact: $e');
    return [];
  }
}

Future<List<AppBatteryImpact>> _fetchBatteryVampires() async {
  try {
    final result = await _channel
        .invokeMethod('getBatteryVampires')
        .timeout(_fetchTimeout);
    return await compute(_parseBatteryImpactData, result);
  } on TimeoutException {
    debugPrint('Battery vampires fetch timed out');
    return [];
  } catch (e) {
    debugPrint('Error fetching battery vampires: $e');
    return [];
  }
}

Future<List<DailyBatteryUsage>> _fetchAppBatteryHistory(
  String packageName, {
  int daysBack = 7,
}) async {
  try {
    final result = await _channel
        .invokeMethod('getAppBatteryHistory', {
          'packageName': packageName,
          'daysBack': daysBack,
        })
        .timeout(_fetchTimeout);
    return await compute(_parseBatteryHistory, result);
  } on TimeoutException {
    debugPrint('Battery history fetch timed out');
    return [];
  } catch (e) {
    debugPrint('Error fetching battery history: $e');
    return [];
  }
}

/// State for battery impact data.
class BatteryImpactState {
  final List<AppBatteryImpact> apps;
  final List<AppBatteryImpact> vampires;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const BatteryImpactState({
    this.apps = const [],
    this.vampires = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  bool get hasData => apps.isNotEmpty;
  bool get hasError => error != null;

  /// Total estimated drain from tracked apps.
  double get totalTrackedDrain =>
      apps.fold(0.0, (sum, app) => sum + app.totalDrain);

  /// Top 5 battery draining apps.
  List<AppBatteryImpact> get topDrainers => apps.take(5).toList();
}

/// Provider for battery impact data.
/// Fetches data on first access and refreshes periodically.
final batteryImpactProvider = StreamProvider.autoDispose<BatteryImpactState>((
  ref,
) {
  late StreamController<BatteryImpactState> controller;
  Timer? refreshTimer;

  controller = StreamController<BatteryImpactState>(
    onListen: () async {
      controller.add(const BatteryImpactState(isLoading: true));

      try {
        // Fetch both in parallel
        final results = await Future.wait([
          _fetchBatteryImpactData(hoursBack: 24),
          _fetchBatteryVampires(),
        ]);

        controller.add(
          BatteryImpactState(
            apps: results[0],
            vampires: results[1],
            isLoading: false,
            lastUpdated: DateTime.now(),
          ),
        );
      } catch (e) {
        controller.add(
          BatteryImpactState(isLoading: false, error: e.toString()),
        );
      }

      // Refresh periodically
      refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }

        try {
          final results = await Future.wait([
            _fetchBatteryImpactData(hoursBack: 24),
            _fetchBatteryVampires(),
          ]);

          controller.add(
            BatteryImpactState(
              apps: results[0],
              vampires: results[1],
              isLoading: false,
              lastUpdated: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Periodic battery impact fetch failed: $e');
        }
      });
    },
    onCancel: () {
      refreshTimer?.cancel();
      controller.close();
    },
  );

  return controller.stream;
});

/// Provider for a specific app's battery history.
final appBatteryHistoryProvider = FutureProvider.autoDispose
    .family<List<DailyBatteryUsage>, String>((ref, packageName) async {
      return _fetchAppBatteryHistory(packageName);
    });
