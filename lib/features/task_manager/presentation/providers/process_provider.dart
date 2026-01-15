library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/active_app.dart';
import '../../domain/entities/android_process.dart';
import '../../domain/entities/system_details.dart';

const _channel = MethodChannel('com.rakhul.unfilter/apps');
const _fetchTimeout = Duration(seconds: 10);
const _refreshInterval = Duration(
  seconds: 3,
); // Balance between real-time and stability
const _activeAppsRefreshInterval = Duration(seconds: 30);

class ProcessFetchException implements Exception {
  final String message;
  final Object? cause;
  const ProcessFetchException(this.message, [this.cause]);

  @override
  String toString() =>
      'ProcessFetchException: $message${cause != null ? ' ($cause)' : ''}';
}

List<AndroidProcess> _parseProcesses(dynamic result) {
  if (result is List) {
    return result.map((e) => AndroidProcess.fromMap(e as Map)).toList();
  }
  return [];
}

SystemDetails _parseSystemDetails(dynamic result) {
  if (result is Map) {
    return SystemDetails.fromMap(result);
  }
  return const SystemDetails(
    memInfo: {},
    cpuTemp: 0,
    gpuUsage: "N/A",
    kernel: "",
  );
}

List<ActiveApp> _parseActiveApps(dynamic result) {
  if (result is List) {
    return result.map((e) => ActiveApp.fromMap(e as Map)).toList();
  }
  return [];
}

Future<List<AndroidProcess>> _fetchProcesses() async {
  try {
    final result = await _channel
        .invokeMethod('getRunningProcesses')
        .timeout(_fetchTimeout);
    return await compute(_parseProcesses, result);
  } on TimeoutException {
    throw const ProcessFetchException('Process fetch timed out');
  } on PlatformException catch (e) {
    throw ProcessFetchException('Platform error', e.message);
  } catch (e) {
    throw ProcessFetchException('Unknown error', e);
  }
}

Future<SystemDetails> _fetchSystemDetails() async {
  try {
    final result = await _channel
        .invokeMethod('getSystemDetails')
        .timeout(_fetchTimeout);
    return await compute(_parseSystemDetails, result);
  } on TimeoutException {
    debugPrint('System details fetch timed out');
    return const SystemDetails(
      memInfo: {},
      cpuTemp: 0,
      gpuUsage: "N/A",
      kernel: "",
    );
  } catch (e) {
    debugPrint('Error fetching system details: $e');
    return const SystemDetails(
      memInfo: {},
      cpuTemp: 0,
      gpuUsage: "N/A",
      kernel: "",
    );
  }
}

Future<List<ActiveApp>> _fetchRecentlyActiveApps({int hoursAgo = 24}) async {
  try {
    final result = await _channel
        .invokeMethod('getRecentlyActiveApps', {'hoursAgo': hoursAgo})
        .timeout(_fetchTimeout);
    return await compute(_parseActiveApps, result);
  } on TimeoutException {
    debugPrint('Active apps fetch timed out');
    return [];
  } catch (e) {
    debugPrint('Error fetching active apps: $e');
    return [];
  }
}

final processProvider = FutureProvider.autoDispose<List<AndroidProcess>>((
  ref,
) async {
  return _fetchProcesses();
});

final systemDetailsProvider = StreamProvider.autoDispose<SystemDetails>((ref) {
  late StreamController<SystemDetails> controller;

  controller = StreamController<SystemDetails>(
    onListen: () async {
      try {
        controller.add(await _fetchSystemDetails());
      } catch (e) {
        debugPrint('Initial system details fetch failed: $e');
      }

      Timer.periodic(_refreshInterval, (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        try {
          controller.add(await _fetchSystemDetails());
        } catch (e) {
          debugPrint('Periodic system details fetch failed: $e');
        }
      });
    },
    onCancel: () => controller.close(),
  );

  return controller.stream;
});

class ProcessListState {
  final List<AndroidProcess> processes;
  final bool isRefreshing;
  final ProcessFetchException? error;
  final DateTime? lastUpdated;

  const ProcessListState({
    this.processes = const [],
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  ProcessListState copyWith({
    List<AndroidProcess>? processes,
    bool? isRefreshing,
    ProcessFetchException? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return ProcessListState(
      processes: processes ?? this.processes,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasData => processes.isNotEmpty;
  bool get hasError => error != null;
}

final activeProcessesProvider = StreamProvider.autoDispose<ProcessListState>((
  ref,
) {
  late StreamController<ProcessListState> controller;
  Timer? refreshTimer;
  ProcessListState currentState = const ProcessListState();

  controller = StreamController<ProcessListState>(
    onListen: () async {
      currentState = const ProcessListState(isRefreshing: true);
      controller.add(currentState);

      try {
        final processes = await _fetchProcesses();
        currentState = ProcessListState(
          processes: processes,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        );
        controller.add(currentState);
      } on ProcessFetchException catch (e) {
        currentState = ProcessListState(isRefreshing: false, error: e);
        controller.add(currentState);
      }

      refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }

        currentState = currentState.copyWith(isRefreshing: true);
        controller.add(currentState);

        try {
          final processes = await _fetchProcesses();
          currentState = ProcessListState(
            processes: processes,
            isRefreshing: false,
            lastUpdated: DateTime.now(),
          );
          controller.add(currentState);
        } on ProcessFetchException catch (e) {
          currentState = currentState.copyWith(isRefreshing: false, error: e);
          controller.add(currentState);
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

/// Independent provider for recently active apps.
/// This fetches data directly from usage stats without requiring a full app scan.
class ActiveAppsState {
  final List<ActiveApp> apps;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ActiveAppsState({
    this.apps = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  bool get hasData => apps.isNotEmpty;
  bool get hasError => error != null;
}

final recentlyActiveAppsProvider = StreamProvider.autoDispose<ActiveAppsState>((
  ref,
) {
  late StreamController<ActiveAppsState> controller;
  Timer? refreshTimer;

  controller = StreamController<ActiveAppsState>(
    onListen: () async {
      controller.add(const ActiveAppsState(isLoading: true));

      try {
        final apps = await _fetchRecentlyActiveApps();
        controller.add(
          ActiveAppsState(
            apps: apps,
            isLoading: false,
            lastUpdated: DateTime.now(),
          ),
        );
      } catch (e) {
        controller.add(ActiveAppsState(isLoading: false, error: e.toString()));
      }

      // Refresh active apps less frequently than processes
      refreshTimer = Timer.periodic(_activeAppsRefreshInterval, (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }

        try {
          final apps = await _fetchRecentlyActiveApps();
          controller.add(
            ActiveAppsState(
              apps: apps,
              isLoading: false,
              lastUpdated: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Periodic active apps fetch failed: $e');
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
