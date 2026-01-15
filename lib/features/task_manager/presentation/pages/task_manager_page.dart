library;

import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';

import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../domain/entities/active_app.dart';
import '../../domain/entities/process_with_history.dart';
import '../providers/task_manager_view_model.dart';
import '../widgets/constants.dart';
import '../widgets/process_list_items.dart';
import '../widgets/system_overview_card.dart';
import '../widgets/task_manager_search_bar.dart';
import '../widgets/task_manager_stage.dart';

class TaskManagerPage extends ConsumerStatefulWidget {
  const TaskManagerPage({super.key});

  @override
  ConsumerState<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends ConsumerState<TaskManagerPage> {
  final Battery _battery = Battery();
  Timer? _refreshTimer;

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  int _totalRam = 0;
  int _freeRam = 0;
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  String _deviceModel = "Unknown Device";
  String _androidVersion = "";

  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initSystemStats();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(TaskManagerDurations.refreshInterval, (
      timer,
    ) {
      _refreshRam();
      _refreshBattery();
    });
  }

  Future<void> _initSystemStats() async {
    await Future.wait([_refreshRam(), _refreshBattery(), _getDeviceInfo()]);

    if (mounted) {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _refreshRam() async {
    try {
      const int mb = 1024 * 1024;
      _totalRam = SysInfo.getTotalPhysicalMemory() ~/ mb;
      _freeRam = SysInfo.getFreePhysicalMemory() ~/ mb;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error refreshing RAM: $e');
    }
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _batteryState = state;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing battery: $e');
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (mounted) {
        setState(() {
          _deviceModel = "${androidInfo.brand} ${androidInfo.model}";
          _androidVersion = "Android ${androidInfo.version.release}";
        });
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
  }

  double _calculateTotalCpu(AsyncValue<TaskManagerData> viewModelState) {
    return viewModelState.maybeWhen(
      data: (data) {
        if (data.processesWithHistory.isEmpty) return 0;
        double total = 0;
        for (final proc in data.processesWithHistory) {
          total += proc.currentCpu;
        }
        return total.clamp(0, 100);
      },
      orElse: () => 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModelState = ref.watch(taskManagerViewModelProvider);

    // Only show loading on initial load, not on refreshes
    final isLoading = _isLoadingStats && viewModelState.isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: TaskManagerStage(
        isLoading: isLoading,
        isRefreshing:
            false, // Never show refresh indicator - data updates silently
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_refreshRam(), _refreshBattery()]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const PremiumSliverAppBar(title: "Task Manager"),

              SliverToBoxAdapter(
                child: SystemOverviewCard(
                  cpuPercentage: _calculateTotalCpu(viewModelState),
                  usedRamMb: _totalRam - _freeRam,
                  totalRamMb: _totalRam,
                  batteryLevel: _batteryLevel,
                  isCharging: _batteryState == BatteryState.charging,
                  deviceModel: _deviceModel,
                  androidVersion: _androidVersion,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TaskManagerSpacing.lg,
                  ),
                  child: TaskManagerSearchBar(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),

              _buildProcessList(viewModelState, theme),

              const SliverPadding(
                padding: EdgeInsets.only(bottom: TaskManagerSpacing.listBottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessList(
    AsyncValue<TaskManagerData> viewModelState,
    ThemeData theme,
  ) {
    return viewModelState.when(
      data: (data) => _buildProcessListContent(data, theme),
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (error, _) => _buildErrorState(theme, error.toString()),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                "Failed to load processes",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(taskManagerViewModelProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessListContent(TaskManagerData data, ThemeData theme) {
    var processesWithHistory = data.processesWithHistory;
    var activeApps = data.activeApps;
    final matches = data.matches;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      processesWithHistory = _filterProcesses(processesWithHistory, query);
      activeApps = _filterActiveApps(activeApps, query);
    }

    final List<Widget> listItems = [];

    if (data.hasProcessError && processesWithHistory.isEmpty) {
      listItems.add(
        _ProcessErrorBanner(
          error: data.processError!.message,
          onRetry: () => ref.invalidate(taskManagerViewModelProvider),
        ),
      );
    }

    if (processesWithHistory.isNotEmpty) {
      listItems.add(
        ProcessSectionHeader(
          title: "KERNEL / SYSTEM",
          trailing: LiveIndicator(color: theme.colorScheme.error),
        ),
      );
      for (var proc in processesWithHistory) {
        listItems.add(EnhancedProcessItem(processWithHistory: proc));
      }
    }

    if (activeApps.isNotEmpty) {
      listItems.add(
        UserSpaceSectionHeader(
          showSandboxedBadge: processesWithHistory.length < 5,
          indicatorColor: theme.colorScheme.primary,
        ),
      );
      for (var app in activeApps) {
        listItems.add(
          UserAppItem(app: app, matchingProcess: matches[app.packageName]),
        );
      }
    }

    if (listItems.isEmpty) {
      return _buildEmptyState(theme);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => listItems[index],
        childCount: listItems.length,
      ),
    );
  }

  List<ProcessWithHistory> _filterProcesses(
    List<ProcessWithHistory> processes,
    String query,
  ) {
    return processes.where((proc) {
      return proc.process.name.toLowerCase().contains(query) ||
          proc.process.user.toLowerCase().contains(query) ||
          proc.process.pid.contains(query);
    }).toList();
  }

  List<ActiveApp> _filterActiveApps(List<ActiveApp> apps, String query) {
    return apps.where((app) {
      return app.appName.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    final message = _searchQuery.isNotEmpty
        ? "No processes match your search"
        : "No process data available";

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchQuery.isNotEmpty)
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            if (_searchQuery.isNotEmpty) const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ProcessErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Process data may be incomplete: $error",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
