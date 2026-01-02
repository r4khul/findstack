import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/app_usage_point.dart';
import '../../domain/entities/device_app.dart';
import '../providers/app_detail_provider.dart';

class AppDetailsPage extends ConsumerWidget {
  final DeviceApp app;

  const AppDetailsPage({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usageHistoryAsync = ref.watch(
      appUsageHistoryProvider(app.packageName),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(app.appName), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 32),

              _buildSectionTitle(theme, "USAGE HISTORY (LAST 7 DAYS)"),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: usageHistoryAsync.when(
                  data: (history) => history.isEmpty
                      ? Center(
                          child: Text(
                            "No usage data available",
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : _buildChart(theme, history),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      "Could not load history",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(theme, "APP INTEGRITY"),
              _buildInfoRow(theme, "Package Name", app.packageName),
              _buildInfoRow(
                theme,
                "Version",
                "${app.version} (${app.versionCode})",
              ),
              _buildInfoRow(theme, "UID", "${app.uid}"),
              _buildInfoRow(theme, "Min SDK", "${app.minSdkVersion}"),
              _buildInfoRow(theme, "Target SDK", "${app.targetSdkVersion}"),
              _buildInfoRow(
                theme,
                "Install Date",
                DateFormat.yMMMd().format(app.installDate),
              ),
              _buildInfoRow(
                theme,
                "Last Update",
                DateFormat.yMMMd().format(app.updateDate),
              ),

              const SizedBox(height: 32),
              if (app.nativeLibraries.isNotEmpty) ...[
                _buildSectionTitle(theme, "NATIVE LIBRARIES"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: app.nativeLibraries
                      .map(
                        (lib) => Chip(
                          label: Text(lib),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 32),
              if (app.permissions.isNotEmpty) ...[
                _buildSectionTitle(theme, "PERMISSIONS"),
                const SizedBox(height: 8),
                ...app.permissions.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• ${p.split('.').last}",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    Color stackColor = Colors.grey;
    if (app.stack == "Flutter")
      stackColor = const Color(0xFF02569B);
    else if (app.stack == "React Native")
      stackColor = const Color(0xFF0D47A1);

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: stackColor.withOpacity(0.1),
          child: Text(
            app.appName[0].toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stackColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: stackColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                app.stack.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(ThemeData theme, List<AppUsagePoint> history) {
    // If all zero, show empty message
    if (history.every((h) => h.usage.inMinutes == 0)) {
      return Center(
        child: Text(
          "No usage recorded in last 7 days",
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            history
                .map((e) => e.usage.inMinutes.toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => theme.colorScheme.surfaceVariant,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = rod.toY.toInt();
              return BarTooltipItem(
                "${minutes}m",
                TextStyle(color: theme.colorScheme.onSurface),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < history.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat.E()
                          .format(history[value.toInt()].date)
                          .substring(0, 1),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: history.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.usage.inMinutes.toDouble(),
                color: theme.colorScheme.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 1440, // 24 hours max? No, just max of view
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary.withOpacity(0.6),
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
