library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/battery_impact.dart';
import '../providers/battery_impact_provider.dart';

/// A card displaying battery impact analysis for apps.
class BatteryImpactCard extends ConsumerStatefulWidget {
  const BatteryImpactCard({super.key});

  @override
  ConsumerState<BatteryImpactCard> createState() => _BatteryImpactCardState();
}

class _BatteryImpactCardState extends ConsumerState<BatteryImpactCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batteryState = ref.watch(batteryImpactProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.error.withOpacity(0.2),
                          theme.colorScheme.error.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.battery_alert_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Battery Impact",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        batteryState.when(
                          data: (state) => Text(
                            state.hasData
                                ? "${state.apps.length} apps analyzed • ${state.totalTrackedDrain.toStringAsFixed(1)}% total"
                                : "Analyzing battery usage...",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          loading: () => Text(
                            "Loading battery data...",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          error: (_, __) => Text(
                            "Unable to load data",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: batteryState.when(
              data: (state) => _BatteryImpactContent(state: state),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error: $error",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _BatteryImpactContent extends StatelessWidget {
  final BatteryImpactState state;

  const _BatteryImpactContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.hasData) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.battery_unknown_rounded,
                size: 40,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "No battery data available",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Use your device normally to collect data",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final topDrainers = state.topDrainers;
    final vampires = state.vampires;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),

        // Top Battery Drainers
        if (topDrainers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  "TOP BATTERY DRAINERS",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                    letterSpacing: 0.5,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ...topDrainers.map((app) => _AppBatteryItem(app: app)),
        ],

        // Battery Vampires
        if (vampires.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 14,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  "BATTERY VAMPIRES",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.tertiary,
                    letterSpacing: 0.5,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "High background activity",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...vampires.take(3).map((app) => _VampireAppItem(app: app)),
        ],

        const SizedBox(height: 12),
      ],
    );
  }
}

class _AppBatteryItem extends StatelessWidget {
  final AppBatteryImpact app;

  const _AppBatteryItem({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // App icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: app.icon != null && app.icon!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      app.icon!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.android_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: 12),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      app.formattedForegroundTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Drain breakdown mini-chips
                    _DrainMiniChips(app: app),
                  ],
                ),
              ],
            ),
          ),

          // Total drain
          _DrainBadge(drain: app.totalDrain),
        ],
      ),
    );
  }
}

class _DrainMiniChips extends StatelessWidget {
  final AppBatteryImpact app;

  const _DrainMiniChips({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = app.drainBreakdown.where((b) => b.value > 0.1).take(2);

    return Row(
      children: breakdown.map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${item.label} ${item.formatted}",
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DrainBadge extends StatelessWidget {
  final double drain;

  const _DrainBadge({required this.drain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;
    if (drain > 10) {
      bgColor = theme.colorScheme.error.withOpacity(0.15);
      textColor = theme.colorScheme.error;
    } else if (drain > 5) {
      bgColor = theme.colorScheme.tertiary.withOpacity(0.15);
      textColor = theme.colorScheme.tertiary;
    } else {
      bgColor = theme.colorScheme.primary.withOpacity(0.1);
      textColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "${drain.toStringAsFixed(1)}%",
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: textColor,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _VampireAppItem extends StatelessWidget {
  final AppBatteryImpact app;

  const _VampireAppItem({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.tertiary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // App icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: app.icon != null && app.icon!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        app.icon!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.android_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 12),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 10,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Woke device ${app.wakeupCount} times today",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Foreground time (low for vampires)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                app.formattedForegroundTime,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact summary widget for showing in the system overview.
class BatteryImpactSummary extends ConsumerWidget {
  const BatteryImpactSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final batteryState = ref.watch(batteryImpactProvider);

    return batteryState.when(
      data: (state) {
        if (!state.hasData) return const SizedBox.shrink();

        final topApp = state.topDrainers.firstOrNull;
        if (topApp == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.battery_alert_rounded,
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                topApp.appName.length > 12
                    ? "${topApp.appName.substring(0, 12)}..."
                    : topApp.appName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                topApp.formattedDrain,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.error,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Shows battery drain history trend for a specific app.
class AppBatteryHistoryChart extends ConsumerWidget {
  final String packageName;

  const AppBatteryHistoryChart({super.key, required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(appBatteryHistoryProvider(packageName));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Text(
              "No battery history available",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final maxDrain = history
            .map((d) => d.estimatedDrain)
            .reduce((a, b) => math.max(a, b))
            .clamp(1.0, 15.0);

        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: history.map((day) {
              final heightRatio = day.estimatedDrain / maxDrain;
              final isToday = DateTime.now().difference(day.date).inDays == 0;

              return Tooltip(
                message:
                    "${day.date.day}/${day.date.month}: ${day.estimatedDrain.toStringAsFixed(1)}%",
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: 50 * heightRatio,
                      decoration: BoxDecoration(
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${day.date.day}",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isToday ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          "Failed to load history",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
