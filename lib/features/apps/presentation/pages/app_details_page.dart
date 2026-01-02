import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/widgets/premium_app_bar.dart';
import '../../domain/entities/app_usage_point.dart';
import '../../domain/entities/device_app.dart';
import '../providers/app_detail_provider.dart';

class AppDetailsPage extends ConsumerWidget {
  final DeviceApp app;

  const AppDetailsPage({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final usageHistoryAsync = ref.watch(
      appUsageHistoryProvider(app.packageName),
    );

    return Scaffold(
      extendBodyBehindAppBar: true, // For blur effect
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PremiumAppBar(title: "App Details"),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 120, // Space for transparent/blur AppBar
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                children: [
                  _buildAppHeader(context, theme, isDark),
                  const SizedBox(height: 32),
                  _buildStatRow(theme, isDark),
                  const SizedBox(height: 32),
                  _buildUsageSection(theme, usageHistoryAsync, isDark),
                  const SizedBox(height: 32),
                  _buildInfoSection(theme, isDark),
                  const SizedBox(height: 32),
                  if (app.nativeLibraries.isNotEmpty) ...[
                    _buildNativeLibsSection(theme, isDark),
                    const SizedBox(height: 32),
                  ],
                  if (app.permissions.isNotEmpty) ...[
                    _buildPermissionsSection(theme, isDark),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context, ThemeData theme, bool isDark) {
    final stackColor = app.stack == "Flutter"
        ? (isDark ? const Color(0xFF42A5F5) : const Color(0xFF02569B))
        : app.stack == "React Native"
        ? (isDark ? const Color(0xFF61DAFB) : const Color(0xFF0D47A1))
        : Colors.grey;

    return Column(
      children: [
        Hero(
          tag: app.packageName,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(app.icon == null ? 24 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: app.icon != null
                  ? Image.memory(app.icon!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        app.appName.isNotEmpty
                            ? app.appName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: stackColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          app.appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          app.packageName,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: stackColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: stackColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                _getStackIconPath(app.stack),
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                app.stack,
                style: TextStyle(
                  color: stackColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, "Version", app.version),
          _buildVerticalDivider(theme),
          _buildStatItem(
            theme,
            "SDK",
            "${app.minSdkVersion} - ${app.targetSdkVersion}",
          ),
          _buildVerticalDivider(theme),
          _buildStatItem(
            theme,
            "Updated",
            DateFormat("MMM d").format(app.updateDate),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageSection(
    ThemeData theme,
    AsyncValue<List<AppUsagePoint>> historyAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Activity"),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: historyAsync.when(
            data: (history) => history.isEmpty
                ? Center(
                    child: Text(
                      "No recent activity",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : _buildChart(theme, history),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                "Unable to load activity",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(ThemeData theme, List<AppUsagePoint> history) {
    if (history.every((h) => h.usage.inMinutes == 0)) {
      return Center(
        child: Text(
          "No usage recorded in last 7 days",
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
                1.2 +
            10, // Add buffer
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                theme.colorScheme.inverseSurface, // Modern tooltip color
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = rod.toY.toInt();
              // Format duration nicely
              String time = "${minutes}m";
              if (minutes > 60) {
                time = "${minutes ~/ 60}h ${minutes % 60}m";
              }

              return BarTooltipItem(
                time,
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
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
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      DateFormat.E()
                          .format(history[value.toInt()].date)
                          .substring(0, 1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
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
                color: theme.colorScheme.primary, // Use primary color
                width: 12,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY:
                      1440, // Should be relative to max Y really, but keeping simplified
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Details"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildDetailItem(
                theme,
                "Package",
                app.packageName,
                showDivider: true,
              ),
              _buildDetailItem(
                theme,
                "UID",
                app.uid.toString(),
                showDivider: true,
              ),
              _buildDetailItem(
                theme,
                "Install Date",
                DateFormat.yMMMd().format(app.installDate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    ThemeData theme,
    String label,
    String value, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
      ],
    );
  }

  Widget _buildNativeLibsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Native Libraries"),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: app.nativeLibraries
              .map(
                (lib) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lib,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Permissions"),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: app.permissions
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.split('.').last,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  String _getStackIconPath(String stack) {
    switch (stack.toLowerCase()) {
      case 'flutter':
        return 'assets/vectors/icon_flutter.svg';
      case 'react native':
        return 'assets/vectors/icon_reactnative.svg';
      case 'kotlin':
        return 'assets/vectors/icon_kotlin.svg';
      case 'java':
        return 'assets/vectors/icon_java.svg';
      case 'swift':
        return 'assets/vectors/icon_swift.svg';
      case 'ionic':
        return 'assets/vectors/icon_ionic.svg';
      case 'xamarin':
        return 'assets/vectors/icon_xamarin.svg';
      default:
        return 'assets/vectors/icon_android.svg';
    }
  }
}
