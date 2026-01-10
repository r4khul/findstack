import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../widgets/analytics_empty_state.dart';
import '../widgets/analytics_pie_chart.dart';
import '../widgets/analytics_search_bar.dart';
import '../widgets/storage_app_item.dart';
import '../widgets/storage_stats_card.dart';
import '../widgets/top_count_filter_button.dart';

class StorageInsightsPage extends ConsumerStatefulWidget {
  const StorageInsightsPage({super.key});

  @override
  ConsumerState<StorageInsightsPage> createState() =>
      _StorageInsightsPageState();
}

class _StorageInsightsPageState extends ConsumerState<StorageInsightsPage> {
  int _touchedIndex = -1;
  int _showTopCount = 5;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: appsAsync.when(
        data: (apps) => _buildDataState(apps, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDataState(List<DeviceApp> apps, ThemeData theme) {
    final filteredApps = apps.where((app) {
      final query = _searchQuery.toLowerCase();
      return app.appName.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();

    final validApps = filteredApps.where((a) => a.size > 0).toList()
      ..sort((a, b) => b.size.compareTo(a.size));

    if (validApps.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyState(theme, 'No storage info available');
    }

    if (validApps.isEmpty) {
      return _buildEmptyState(theme, 'No apps match your search');
    }

    return _buildStorageContent(validApps, theme);
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return CustomScrollView(
      slivers: [
        const PremiumSliverAppBar(title: 'Storage Insights'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: AnalyticsSearchBar(
              controller: _searchController,
              searchQuery: _searchQuery,
              hintText: 'Search storage...',
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
        ),
        SliverFillRemaining(child: AnalyticsEmptyState(message: message)),
      ],
    );
  }

  Widget _buildStorageContent(List<DeviceApp> validApps, ThemeData theme) {
    final totalSize = validApps.fold<int>(0, (sum, app) => sum + app.size);
    final appCodeSize = validApps.fold<int>(0, (sum, app) => sum + app.appSize);
    final dataSize = validApps.fold<int>(0, (sum, app) => sum + app.dataSize);
    final cacheSize = validApps.fold<int>(0, (sum, app) => sum + app.cacheSize);

    final topAppsForChart = validApps.take(_showTopCount).toList();
    final topSizeForChart = topAppsForChart.fold<int>(
      0,
      (sum, app) => sum + app.size,
    );
    final otherSizeForChart = totalSize - topSizeForChart;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const PremiumSliverAppBar(title: 'Storage Insights'),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        _buildSearchBarSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildStatsCardSliver(totalSize, appCodeSize, dataSize, cacheSize),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildFilterSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        _buildChartSliver(topAppsForChart, otherSizeForChart, totalSize),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildAppListSliver(validApps, totalSize, theme),
      ],
    );
  }

  Widget _buildSearchBarSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnalyticsSearchBar(
          controller: _searchController,
          searchQuery: _searchQuery,
          hintText: 'Search storage...',
          onChanged: (val) => setState(() => _searchQuery = val),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
      ),
    );
  }

  Widget _buildStatsCardSliver(
    int totalSize,
    int appCodeSize,
    int dataSize,
    int cacheSize,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StorageStatsCard(
          totalSize: totalSize,
          appCodeSize: appCodeSize,
          dataSize: dataSize,
          cacheSize: cacheSize,
          isFiltered: _searchQuery.isNotEmpty,
        ),
      ),
    );
  }

  Widget _buildFilterSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerRight,
          child: TopCountFilterButton(
            currentCount: _showTopCount,
            onCountSelected: (value) => setState(() => _showTopCount = value),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSliver(
    List<DeviceApp> topApps,
    int otherSize,
    int totalSize,
  ) {
    return SliverToBoxAdapter(
      child: AnalyticsPieChart(
        apps: topApps,
        total: totalSize,
        otherValue: otherSize,
        touchedIndex: _touchedIndex,
        onSectionTouched: (index) => setState(() => _touchedIndex = index),
        getValue: (app) => app.size,
        formatTotal: _formatBytes,
        centerLabel: 'Total',
      ),
    );
  }

  Widget _buildAppListSliver(
    List<DeviceApp> validApps,
    int totalSize,
    ThemeData theme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _searchQuery.isEmpty ? 'HEAVIEST APPS' : 'SEARCH RESULTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            );
          }
          final appIndex = index - 1;
          final app = validApps[appIndex];
          final percent = app.size / (totalSize > 0 ? totalSize : 1);
          final isTouched = appIndex == _touchedIndex;

          return StorageAppItem(
            key: ValueKey(app.packageName),
            app: app,
            percent: percent,
            index: appIndex,
            isTouched: isTouched,
            onTapDown: () => setState(() => _touchedIndex = appIndex),
            onTapCancel: () => setState(() => _touchedIndex = -1),
          );
        }, childCount: validApps.length + 1),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
