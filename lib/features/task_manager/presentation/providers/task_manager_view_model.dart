/// View model provider for the Task Manager page.
///
/// This provider combines process data with installed apps to provide
/// a unified view of active applications and their resource usage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../domain/entities/android_process.dart';
import 'process_provider.dart';

/// Data model containing all information needed by the Task Manager UI.
///
/// Combines shell processes with active user apps and provides
/// matching information to correlate apps with their processes.
///
/// ## Fields
/// - [shellProcesses]: Raw processes from the system
/// - [activeApps]: User apps active in the last 24 hours
/// - [matches]: Map of package names to their matching processes
class TaskManagerData {
  /// List of all detected shell/system processes.
  final List<AndroidProcess> shellProcesses;

  /// List of user apps active in the last 24 hours.
  ///
  /// Sorted by most recently used.
  final List<DeviceApp> activeApps;

  /// Map correlating package names to their running processes.
  ///
  /// Only populated for apps that have a matching process.
  final Map<String, AndroidProcess> matches;

  /// Creates a task manager data instance.
  const TaskManagerData({
    this.shellProcesses = const [],
    this.activeApps = const [],
    this.matches = const {},
  });
}

/// Provider that combines process and app data for the Task Manager.
///
/// This provider:
/// 1. Watches installed apps and active processes
/// 2. Filters apps to only those active in the last 24 hours
/// 3. Sorts active apps by most recently used
/// 4. Matches apps to their running processes by package name
///
/// Returns [AsyncValue.loading] while either data source is loading.
/// Returns [AsyncValue.error] if either data source fails.
///
/// ## Usage
/// ```dart
/// final viewModel = ref.watch(taskManagerViewModelProvider);
/// viewModel.when(
///   data: (data) => buildUI(data),
///   loading: () => showLoading(),
///   error: (e, s) => showError(e),
/// );
/// ```
final taskManagerViewModelProvider =
    Provider.autoDispose<AsyncValue<TaskManagerData>>((ref) {
      final appsState = ref.watch(installedAppsProvider);
      final processesState = ref.watch(activeProcessesProvider);

      // Wait for both data sources
      if (appsState.isLoading || processesState.isLoading) {
        return const AsyncValue.loading();
      }

      // Propagate errors
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

      // Filter: Active in last 24 hours
      final activeApps = _filterRecentlyActiveApps(userApps);

      // Sort by most recent
      activeApps.sort((a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed));

      // Match processes to apps
      final matches = _matchProcessesToApps(activeApps, shellProcesses);

      return AsyncValue.data(
        TaskManagerData(
          shellProcesses: shellProcesses,
          activeApps: activeApps,
          matches: matches,
        ),
      );
    });

/// Filters apps to only those active in the last 24 hours.
List<DeviceApp> _filterRecentlyActiveApps(List<DeviceApp> apps) {
  return apps.where((app) {
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);
    return diff.inHours < 24;
  }).toList();
}

/// Matches apps to their running processes.
///
/// Creates a map of package names to processes by checking if
/// either the process name contains the package name or vice versa.
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
      // No match found - this is expected for cached apps
    }
  }

  return matches;
}
