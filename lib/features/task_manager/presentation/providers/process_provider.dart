import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/android_process.dart';
import '../../domain/entities/system_details.dart';

const _channel = MethodChannel('com.rakhul.unfilter/apps');

/// Parsers for off-thread processing
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

final processProvider = FutureProvider.autoDispose<List<AndroidProcess>>((
  ref,
) async {
  try {
    final result = await _channel.invokeMethod('getRunningProcesses');
    return await compute(_parseProcesses, result);
  } catch (e) {
    return [];
  }
});

final systemDetailsProvider = StreamProvider.autoDispose<SystemDetails>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (count) => count).asyncMap(
    (_) async {
      try {
        final result = await _channel.invokeMethod('getSystemDetails');
        return await compute(_parseSystemDetails, result);
      } catch (e) {
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
          return <AndroidProcess>[];
        }
      });
    });
