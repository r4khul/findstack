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
      // system_info2 mostly works on desktop/android
      // On some Android versions, it might fail or return 0. Handle gracefully.
      const int mb = 1024 * 1024;
      _totalRam = SysInfo.getTotalPhysicalMemory() ~/ mb;
      _freeRam = SysInfo.getFreePhysicalMemory() ~/ mb;
      setState(() {});
    } catch (e) {
      // Fallback or ignore
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
    final appsAsync = ref.watch(installedAppsProvider);

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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "RECENT PROCESSES",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const Spacer(),
                  // Blinking indicator for "Live" feel
                  _LiveIndicator(color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),

          // Process List
          appsAsync.when(
            data: (apps) {
              // Sort by recently used
              final activeApps = apps
                  .where((app) => app.lastTimeUsed > 0)
                  .toList();
              activeApps.sort(
                (a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed),
              );

              // If no usage stats, fall back to just all apps (unlikely if usage stats working)
              final displayApps = activeApps.isEmpty ? apps : activeApps;

              if (displayApps.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No active processes found")),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final app = displayApps[index];
                  return _buildProcessItem(context, theme, app);
                }, childCount: displayApps.length),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Skeletonizer(
                enabled: true,
                child: Column(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text("Error: $err"))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildSystemStatsCard(ThemeData theme) {
    // Calculate RAM usage
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

          // RAM Usage
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

          // Battery Usage
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

  Widget _buildProcessItem(
    BuildContext context,
    ThemeData theme,
    DeviceApp app,
  ) {
    // Format timestamp
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
            // Navigate to app details
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
                        "RUNNING", // Mimic "Running" state
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
