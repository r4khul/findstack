library;

import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';

import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../domain/entities/android_process.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../providers/task_manager_view_model.dart';
import '../widgets/constants.dart';
import '../widgets/process_list_items.dart';
import '../widgets/system_stats_card.dart';
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
    final minWait = Future.delayed(TaskManagerDurations.minLoadingWait);
    final fetchTask = Future.wait([
      _refreshRam(),
      _refreshBattery(),
      _getDeviceInfo(),
    ]);

    await Future.wait([minWait, fetchTask]);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModelState = ref.watch(taskManagerViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: TaskManagerStage(
        isLoading: _isLoadingStats || viewModelState.isLoading,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const PremiumSliverAppBar(title: "Task Manager"),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(TaskManagerSpacing.lg),
                child: SystemStatsCard(
                  deviceModel: _deviceModel,
                  androidVersion: _androidVersion,
                  totalRam: _totalRam,
                  freeRam: _freeRam,
                  batteryLevel: _batteryLevel,
                  batteryState: _batteryState,
                ),
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
    );
  }

  Widget _buildProcessList(
    AsyncValue<TaskManagerData> viewModelState,
    ThemeData theme,
  ) {
    return viewModelState.when(
      data: (data) => _buildProcessListContent(data, theme),
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverFillRemaining(
        child: Center(child: Text("Error loading tasks")),
      ),
    );
  }

  Widget _buildProcessListContent(TaskManagerData data, ThemeData theme) {
    var shellProcesses = data.shellProcesses;
    var activeApps = data.activeApps;
    final matches = data.matches;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      shellProcesses = _filterShellProcesses(shellProcesses, query);
      activeApps = _filterActiveApps(activeApps, query);
    }

    final List<Widget> listItems = [];

    if (shellProcesses.isNotEmpty) {
      listItems.add(
        ProcessSectionHeader(
          title: "KERNEL / SYSTEM",
          trailing: LiveIndicator(color: theme.colorScheme.error),
        ),
      );
      for (var proc in shellProcesses) {
        listItems.add(ShellProcessItem(process: proc));
      }
    }

    if (activeApps.isNotEmpty) {
      listItems.add(
        UserSpaceSectionHeader(
          showSandboxedBadge: shellProcesses.length < 5,
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

  List<AndroidProcess> _filterShellProcesses(
    List<AndroidProcess> processes,
    String query,
  ) {
    return processes.where((proc) {
      return proc.name.toLowerCase().contains(query) ||
          proc.user.toLowerCase().contains(query) ||
          proc.pid.contains(query);
    }).toList();
  }

  List<DeviceApp> _filterActiveApps(List<DeviceApp> apps, String query) {
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
