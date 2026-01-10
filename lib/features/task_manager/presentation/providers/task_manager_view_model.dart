library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../domain/entities/android_process.dart';
import 'process_provider.dart';

class TaskManagerData {
  final List<AndroidProcess> shellProcesses;

  final List<DeviceApp> activeApps;

  final Map<String, AndroidProcess> matches;

  const TaskManagerData({
    this.shellProcesses = const [],
    this.activeApps = const [],
    this.matches = const {},
  });
}

final taskManagerViewModelProvider =
    Provider.autoDispose<AsyncValue<TaskManagerData>>((ref) {
      final appsState = ref.watch(installedAppsProvider);
      final processesState = ref.watch(activeProcessesProvider);

      if (appsState.isLoading || processesState.isLoading) {
        return const AsyncValue.loading();
      }

      if (appsState.hasError) {
        return AsyncValue.error(appsState.error!, appsState.stackTrace!);
      }
      if (processesState.hasError) {
        return AsyncValue.error(
          processesState.error!,
          processesState.stackTrace!,
        );
      }

      final shellProcesses = processesState.value ?? [];
      final userApps = appsState.value ?? [];

      final activeApps = _filterRecentlyActiveApps(userApps);

      activeApps.sort((a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed));

      final matches = _matchProcessesToApps(activeApps, shellProcesses);

      return AsyncValue.data(
        TaskManagerData(
          shellProcesses: shellProcesses,
          activeApps: activeApps,
          matches: matches,
        ),
      );
    });

List<DeviceApp> _filterRecentlyActiveApps(List<DeviceApp> apps) {
  return apps.where((app) {
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);
    return diff.inHours < 24;
  }).toList();
}

Map<String, AndroidProcess> _matchProcessesToApps(
  List<DeviceApp> apps,
  List<AndroidProcess> processes,
) {
  final matches = <String, AndroidProcess>{};

  for (final app in apps) {
    try {
      final match = processes.firstWhere(
        (p) =>
            p.name.contains(app.packageName) ||
            app.packageName.contains(p.name),
      );
      matches[app.packageName] = match;
    } catch (_) {
    }
  }

  return matches;
}
