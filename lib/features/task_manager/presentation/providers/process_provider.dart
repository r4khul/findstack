import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/android_process.dart';

const _channel = MethodChannel('com.rakhul.unfilter/apps');

final processProvider = FutureProvider.autoDispose<List<AndroidProcess>>((
  ref,
) async {
  try {
    final result = await _channel.invokeMethod('getRunningProcesses');
    if (result is List) {
      return result.map((e) => AndroidProcess.fromMap(e as Map)).toList();
    }
    return [];
  } catch (e) {
    // Fail silently or return empty, allowing UI to handle "no data"
    return [];
  }
});

// A provider that refreshes periodically
final activeProcessesProvider =
    StreamProvider.autoDispose<List<AndroidProcess>>((ref) {
      return Stream.periodic(const Duration(seconds: 2), (computationCount) {
        return computationCount;
      }).asyncMap((_) async {
        // Manually invoking the future logic
        try {
          final result = await _channel.invokeMethod('getRunningProcesses');
          if (result is List) {
            return result.map((e) => AndroidProcess.fromMap(e as Map)).toList();
          }
          return <AndroidProcess>[];
        } catch (e) {
          return <AndroidProcess>[];
        }
      });
    });
