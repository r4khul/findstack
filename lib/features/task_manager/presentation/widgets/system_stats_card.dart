library;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/process_provider.dart';
import 'constants.dart';

class SystemStatsCard extends ConsumerWidget {
  final String deviceModel;

  final String androidVersion;

  final int totalRam;

  final int freeRam;

  final int batteryLevel;

  final BatteryState batteryState;

  const SystemStatsCard({
    super.key,
    required this.deviceModel,
    required this.androidVersion,
    required this.totalRam,
    required this.freeRam,
    required this.batteryLevel,
    required this.batteryState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final systemDetailsValues = ref.watch(systemDetailsProvider).asData?.value;

    final int usedRam = totalRam - freeRam;
    final double ramPercent = totalRam > 0 ? usedRam / totalRam : 0.0;

    final int cachedKb = systemDetailsValues?.cachedRealKb ?? 0;
    final int cachedMb = cachedKb ~/ 1024;

    final String gpuUsage = systemDetailsValues?.gpuUsage ?? "N/A";
    final double cpuTemp = systemDetailsValues?.cpuTemp ?? 0.0;
    final String kernelVer = systemDetailsValues?.kernel ?? "Loading...";

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(TaskManagerBorderRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(
            TaskManagerOpacity.mediumLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(TaskManagerOpacity.subtle),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TaskManagerSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceHeader(theme, kernelVer),
                const SizedBox(height: TaskManagerSpacing.xl),
                _buildRamUsage(theme, usedRam, ramPercent),
                if (cachedMb > 0) _buildCachedRamIndicator(theme, cachedMb),
                const SizedBox(height: TaskManagerSpacing.lg),
                _buildBatteryUsage(theme),
              ],
            ),
          ),
          Divider(
            height: TaskManagerSizes.dividerWidth,
            color: theme.colorScheme.outlineVariant.withOpacity(
              TaskManagerOpacity.mediumLight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(TaskManagerSpacing.lg),
            child: _buildBottomStatsGrid(theme, gpuUsage, cpuTemp),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader(ThemeData theme, String kernelVer) {
    final displayKernel = kernelVer.length > 20
        ? "${kernelVer.substring(0, 20)}..."
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
              Text(
                "Kernel: $displayKernel",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(
          Icons.developer_board,
          size: TaskManagerSizes.iconSizeLarge,
          color: theme.colorScheme.primary.withOpacity(
            TaskManagerOpacity.nearlyOpaque,
          ),
        ),
      ],
    );
  }

  Widget _buildRamUsage(ThemeData theme, int usedRam, double ramPercent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Memory Usage", style: theme.textTheme.labelMedium),
            Text(
              "${usedRam}MB / ${totalRam}MB",
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: TaskManagerSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(TaskManagerBorderRadius.sm),
          child: LinearProgressIndicator(
            value: ramPercent,
            minHeight: TaskManagerSizes.progressBarHeight,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              ramPercent > 0.85
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCachedRamIndicator(ThemeData theme, int cachedMb) {
    return Padding(
      padding: const EdgeInsets.only(top: TaskManagerSpacing.sm),
      child: Row(
        children: [
          Container(
            width: TaskManagerSizes.liveIndicatorDotSize,
            height: TaskManagerSizes.liveIndicatorDotSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TaskManagerSpacing.sm + 2),
          Text(
            "Cached Processes: ${cachedMb}MB",
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: TaskManagerFontSizes.sm,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryUsage(ThemeData theme) {
    final isCharging = batteryState == BatteryState.charging;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Battery Power", style: theme.textTheme.labelMedium),
            Row(
              children: [
                if (isCharging)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: TaskManagerSpacing.sm,
                    ),
                    child: Icon(
                      Icons.bolt,
                      size: TaskManagerSizes.iconSizeSmall,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Text(
                  "$batteryLevel%",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TaskManagerSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(TaskManagerBorderRadius.sm),
          child: LinearProgressIndicator(
            value: batteryLevel / 100,
            minHeight: TaskManagerSizes.progressBarHeight,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              batteryLevel < 20
                  ? theme.colorScheme.error
                  : isCharging
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
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
          label: "GPU CORE",
          value: gpuUsage.contains('N/A') ? "LOCKED" : gpuUsage,
          isError: gpuUsage.contains('N/A'),
        ),
        _StatDivider(),
        _MiniStat(label: "THERMAL", value: "${cpuTemp.toStringAsFixed(1)}°C"),
        _StatDivider(),
        _MiniStat(
          label: "ANDROID",
          value: androidVersion.replaceAll("Android ", ""),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _MiniStat({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: TaskManagerFontSizes.xs,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(
              TaskManagerOpacity.high,
            ),
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TaskManagerSpacing.sm),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: TaskManagerSizes.dividerWidth,
      height: TaskManagerSizes.dividerHeight,
      color: theme.colorScheme.outlineVariant.withOpacity(
        TaskManagerOpacity.mediumLight,
      ),
    );
  }
}
