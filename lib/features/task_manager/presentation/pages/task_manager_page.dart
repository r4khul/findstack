import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../../apps/presentation/pages/app_details_page.dart';
import '../providers/process_provider.dart';
import '../../domain/entities/android_process.dart';

class TaskManagerPage extends ConsumerStatefulWidget {
  const TaskManagerPage({super.key});

  @override
  ConsumerState<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends ConsumerState<TaskManagerPage> {
  final Battery _battery = Battery();
  Timer? _refreshTimer;

  // System Stats
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
    // Refresh stats every 3 seconds to give a "live" feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshRam();
      _refreshBattery();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
      // Fallback
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
      // Ignore
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
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(title: "Task Manager"),

          // System Stats Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Skeletonizer(
                enabled: _isLoadingStats,
                child: _buildSystemStatsCard(theme),
              ),
            ),
          ),

          // Unified List Logic
          Consumer(
            builder: (context, ref, child) {
              final appsState = ref.watch(installedAppsProvider);
              final processesState = ref.watch(activeProcessesProvider);

              // 1. Get Shell Processes (Kernel layer)
              final shellProcesses = processesState.asData?.value ?? [];

              // 2. Get User Apps (Application layer)
              final userApps = appsState.asData?.value ?? [];

              final List<Widget> listItems = [];

              // HEADER: KERNEL / SYSTEM
              if (shellProcesses.isNotEmpty) {
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          "KERNEL / SYSTEM",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const Spacer(),
                        _LiveIndicator(color: theme.colorScheme.error),
                      ],
                    ),
                  ),
                );

                for (var proc in shellProcesses) {
                  listItems.add(_buildShellProcessItem(context, theme, proc));
                }
              }

              // HEADER: USER APPS
              if (userApps.isNotEmpty) {
                // Filter: Active in last 24h
                final activeApps = userApps.where((app) {
                  final lastUsed = DateTime.fromMillisecondsSinceEpoch(
                    app.lastTimeUsed,
                  );
                  final diff = DateTime.now().difference(lastUsed);
                  return diff.inHours < 24;
                }).toList();

                // Sort by most recent
                activeApps.sort(
                  (a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed),
                );

                if (activeApps.isNotEmpty) {
                  listItems.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            "USER SPACE (ACTIVE)",
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (shellProcesses.length < 5)
                            Text(
                              "SANDBOXED",
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.5),
                              ),
                            )
                          else
                            _LiveIndicator(color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  );

                  for (var app in activeApps) {
                    // Try to find matching shell process for potentially more info
                    AndroidProcess? matchingProc;
                    try {
                      matchingProc = shellProcesses.firstWhere(
                        (p) =>
                            p.name.contains(app.packageName) ||
                            app.packageName.contains(p.name),
                      );
                    } catch (_) {}

                    listItems.add(
                      _buildUsageBasedItem(
                        context,
                        theme,
                        app,
                        matchingShell: matchingProc,
                      ),
                    );
                  }
                }
              }

              if (listItems.isEmpty) {
                if (appsState.isLoading || processesState.isLoading) {
                  return _buildSkeletonList();
                }
                return const SliverFillRemaining(
                  child: Center(child: Text("No process data available")),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => listItems[index],
                  childCount: listItems.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return SliverToBoxAdapter(
      child: Skeletonizer(
        enabled: true,
        child: Column(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatsCard(ThemeData theme) {
    final int usedRam = _totalRam - _freeRam;
    final double ramPercent = _totalRam > 0 ? usedRam / _totalRam : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _deviceModel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _androidVersion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.memory_rounded,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Memory Usage", style: theme.textTheme.labelMedium),
              Text(
                "${usedRam}MB / ${_totalRam}MB",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ramPercent,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                ramPercent > 0.85
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Battery Power", style: theme.textTheme.labelMedium),
              Row(
                children: [
                  if (_batteryState == BatteryState.charging)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.bolt,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    "$_batteryLevel%",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _batteryLevel / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _batteryLevel < 20
                    ? theme.colorScheme.error
                    : _batteryState == BatteryState.charging
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Uses shell data (Pro mode)
  Widget _buildShellProcessItem(
    BuildContext context,
    ThemeData theme,
    AndroidProcess process,
  ) {
    final bool isRoot = process.user == 'root';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRoot
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                process.pid,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isRoot
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    process.name.length > 30
                        ? "...${process.name.substring(process.name.length - 28)}"
                        : process.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        process.user,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 10,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RSS: ${process.res}", // Already formatted usually? ps returns integer usually in kb
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${process.cpu}%",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: process.cpu != "0.0" && process.cpu != "0"
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "CPU",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fallback using usage stats
  Widget _buildUsageBasedItem(
    BuildContext context,
    ThemeData theme,
    DeviceApp app, {
    AndroidProcess? matchingShell,
  }) {
    // ... Copy of previous logic ...
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);

    String timeAgo;
    if (diff.inSeconds < 60) {
      timeAgo = "Active now";
    } else if (diff.inMinutes < 60) {
      timeAgo = "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      timeAgo = "${diff.inHours}h ago";
    } else {
      timeAgo = "${diff.inDays}d ago";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AppDetailsPage(app: app)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'task_manager_${app.packageName}',
                  child: _AppIcon(app: app, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        app.packageName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (matchingShell != null) ...[
                      Text(
                        "${matchingShell.cpu}% CPU",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        "RSS: ${matchingShell.res}",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ] else ...[
                      Text(
                        timeAgo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: diff.inMinutes < 5
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: diff.inMinutes < 5
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "CACHED",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final DeviceApp app;
  final double size;

  const _AppIcon({required this.app, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: app.icon != null
            ? Image.memory(
                app.icon!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Icon(Icons.android),
              )
            : const Icon(Icons.android),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  final Color color;
  const _LiveIndicator({required this.color});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "LIVE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
