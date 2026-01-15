library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/process_provider.dart';
import 'system_gauges.dart';

/// Fused system overview that combines animated gauges with device info.
class SystemOverviewCard extends ConsumerWidget {
  final double cpuPercentage;
  final int usedRamMb;
  final int totalRamMb;
  final int batteryLevel;
  final bool isCharging;
  final String deviceModel;
  final String androidVersion;

  const SystemOverviewCard({
    super.key,
    required this.cpuPercentage,
    required this.usedRamMb,
    required this.totalRamMb,
    required this.batteryLevel,
    required this.isCharging,
    required this.deviceModel,
    required this.androidVersion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final systemDetailsValues = ref.watch(systemDetailsProvider).asData?.value;

    final double cpuTemp = systemDetailsValues?.cpuTemp ?? 0.0;
    final String gpuUsage = systemDetailsValues?.gpuUsage ?? "N/A";
    final String kernelVer = systemDetailsValues?.kernel ?? "Loading...";
    final int cachedKb = systemDetailsValues?.cachedRealKb ?? 0;
    final int cachedMb = cachedKb ~/ 1024;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section: Device header + gauges
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device header row
                _buildDeviceHeader(theme, kernelVer),
                const SizedBox(height: 20),

                // Main gauges row
                Row(
                  children: [
                    // CPU Gauge
                    CpuGauge(percentage: cpuPercentage, size: 80),
                    const SizedBox(width: 20),
                    // Right column: Memory + Battery
                    Expanded(
                      child: Column(
                        children: [
                          MemoryBar(usedMb: usedRamMb, totalMb: totalRamMb),
                          if (cachedMb > 0) ...[
                            const SizedBox(height: 6),
                            _buildCachedIndicator(theme, cachedMb),
                          ],
                          const SizedBox(height: 12),
                          _buildBatteryRow(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          ),

          // Bottom stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _buildBottomStatsGrid(theme, gpuUsage, cpuTemp),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader(ThemeData theme, String kernelVer) {
    final displayKernel = kernelVer.length > 25
        ? "${kernelVer.substring(0, 25)}..."
        : kernelVer;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceModel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Kernel: $displayKernel",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.developer_board_rounded,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCachedIndicator(ThemeData theme, int cachedMb) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "Cached: ${cachedMb}MB",
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryRow(ThemeData theme) {
    final batteryColor = _getBatteryColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: batteryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: batteryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(_getBatteryIcon(), size: 18, color: batteryColor),
          const SizedBox(width: 8),
          Text(
            '$batteryLevel%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 13,
              color: batteryColor,
            ),
          ),
          if (isCharging) ...[
            const SizedBox(width: 4),
            Icon(Icons.bolt_rounded, size: 14, color: batteryColor),
          ],
          const Spacer(),
          Text(
            isCharging ? 'Charging' : 'Battery',
            style: theme.textTheme.labelSmall?.copyWith(
              color: batteryColor.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor() {
    if (isCharging) return const Color(0xFF4CAF50);
    if (batteryLevel > 50) return const Color(0xFF4CAF50);
    if (batteryLevel > 20) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  IconData _getBatteryIcon() {
    if (isCharging) return Icons.battery_charging_full_rounded;
    if (batteryLevel > 90) return Icons.battery_full_rounded;
    if (batteryLevel > 60) return Icons.battery_5_bar_rounded;
    if (batteryLevel > 40) return Icons.battery_4_bar_rounded;
    if (batteryLevel > 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  Widget _buildBottomStatsGrid(
    ThemeData theme,
    String gpuUsage,
    double cpuTemp,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MiniStat(
          icon: Icons.memory_rounded,
          label: "GPU",
          value: gpuUsage.contains('N/A') ? "LOCKED" : gpuUsage,
          isLocked: gpuUsage.contains('N/A'),
        ),
        _buildVerticalDivider(theme),
        _MiniStat(
          icon: Icons.thermostat_rounded,
          label: "TEMP",
          value: "${cpuTemp.toStringAsFixed(1)}°",
          isWarning: cpuTemp > 45,
        ),
        _buildVerticalDivider(theme),
        _MiniStat(
          icon: Icons.android_rounded,
          label: "OS",
          value: androidVersion.replaceAll("Android ", ""),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLocked;
  final bool isWarning;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.isLocked = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLocked
        ? theme.colorScheme.error.withOpacity(0.7)
        : isWarning
        ? const Color(0xFFFF9800)
        : theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
