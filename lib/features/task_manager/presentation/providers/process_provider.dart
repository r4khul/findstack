/// Providers for accessing system process and device information.
///
/// This file contains Riverpod providers that interface with native Android
/// code to fetch process lists and system details.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/android_process.dart';
import '../../domain/entities/system_details.dart';

/// Platform channel for communicating with native Android code.
const _channel = MethodChannel('com.rakhul.unfilter/apps');

// =============================================================================
// PARSERS (Run on isolate for performance)
// =============================================================================

/// Parses raw process data from native code.
///
/// Runs on a separate isolate to avoid blocking the UI thread.
List<AndroidProcess> _parseProcesses(dynamic result) {
  if (result is List) {
    return result.map((e) => AndroidProcess.fromMap(e as Map)).toList();
  }
  return [];
}

/// Parses system details from native code.
///
/// Runs on a separate isolate to avoid blocking the UI thread.
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

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provides a one-time snapshot of running processes.
///
/// Fetches the current list of running Android processes from native code.
/// The result is parsed on a separate isolate for performance.
///
/// Auto-disposes when no longer watched.
///
/// ## Usage
/// ```dart
/// final processes = ref.watch(processProvider);
/// processes.when(
///   data: (list) => showProcesses(list),
///   loading: () => showLoading(),
///   error: (e, s) => showError(e),
/// );
/// ```
final processProvider = FutureProvider.autoDispose<List<AndroidProcess>>((
  ref,
) async {
  try {
    final result = await _channel.invokeMethod('getRunningProcesses');
    return await compute(_parseProcesses, result);
  } catch (e) {
    debugPrint('Error fetching processes: $e');
    return [];
  }
});

/// Provides a stream of system details, updated every 5 seconds.
///
/// Fetches system information including:
/// - Memory stats from /proc/meminfo
/// - CPU temperature
/// - GPU usage (if available)
/// - Kernel version
///
/// Auto-disposes when no longer watched.
///
/// ## Usage
/// ```dart
/// final systemDetails = ref.watch(systemDetailsProvider);
/// systemDetails.when(
///   data: (details) => showDetails(details),
///   loading: () => showLoading(),
///   error: (e, s) => showError(e),
/// );
/// ```
final systemDetailsProvider = StreamProvider.autoDispose<SystemDetails>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (count) => count).asyncMap(
    (_) async {
      try {
        final result = await _channel.invokeMethod('getSystemDetails');
        return await compute(_parseSystemDetails, result);
      } catch (e) {
        debugPrint('Error fetching system details: $e');
        return const SystemDetails(
          memInfo: {},
          cpuTemp: 0,
          gpuUsage: "N/A",
          kernel: "",
        );
      }
    },
  );
});

/// Provides a stream of running processes, updated every 5 seconds.
///
/// Similar to [processProvider] but provides continuous updates
/// as a stream rather than a one-time snapshot.
///
/// This is used by the task manager to show live process information.
///
/// Auto-disposes when no longer watched.
final activeProcessesProvider =
    StreamProvider.autoDispose<List<AndroidProcess>>((ref) {
      return Stream.periodic(
        const Duration(seconds: 5),
        (count) => count,
      ).asyncMap((_) async {
        try {
          final result = await _channel.invokeMethod('getRunningProcesses');
          return await compute(_parseProcesses, result);
        } catch (e) {
          debugPrint('Error fetching active processes: $e');
          return <AndroidProcess>[];
        }
      });
    });
