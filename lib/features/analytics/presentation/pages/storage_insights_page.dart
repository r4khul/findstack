import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

class StorageInsightsPage extends ConsumerStatefulWidget {
  const StorageInsightsPage({super.key});

  @override
  ConsumerState<StorageInsightsPage> createState() =>
      _StorageInsightsPageState();
}

class _StorageInsightsPageState extends ConsumerState<StorageInsightsPage> {
  int _touchedIndex = -1;
  int _showTopCount = 5;
  String _searchQuery = "";
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
      // Use CustomScrollView with SliverAppBar for search bar at top
      body: appsAsync.when(
        data: (apps) {
          // 1. Filter by Search Query
          final filteredApps = apps.where((app) {
            final query = _searchQuery.toLowerCase();
            return app.appName.toLowerCase().contains(query) ||
                app.packageName.toLowerCase().contains(query);
          }).toList();

          // 2. Filter by Size > 0
          final validApps = filteredApps.where((a) => a.size > 0).toList();

          // 3. Sort by Size Descending
          validApps.sort((a, b) => b.size.compareTo(a.size));

          if (validApps.isEmpty && _searchQuery.isEmpty) {
            return _buildEmptyState(theme, "No storage info available");
          } else if (validApps.isEmpty) {
            return _buildEmptyState(theme, "No apps match your search");
          }

          final totalSize = validApps.fold<int>(
            0,
            (sum, app) => sum + app.size,
          );
          final appCodeSize = validApps.fold<int>(
            0,
            (sum, app) => sum + app.appSize,
          );
          final dataSize = validApps.fold<int>(
            0,
            (sum, app) => sum + app.dataSize,
          );
          final cacheSize = validApps.fold<int>(
            0,
            (sum, app) => sum + app.cacheSize,
          );

          // Top apps for Chart
          final topAppsForChart = validApps.take(_showTopCount).toList();
          final topSizeForChart = topAppsForChart.fold<int>(
            0,
            (sum, app) => sum + app.size,
          );
          final otherSizeForChart = totalSize - topSizeForChart;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const PremiumSliverAppBar(title: "Storage Insights"),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Global Stats Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildGlobalStatsCard(
                    theme,
                    totalSize,
                    appCodeSize,
                    dataSize,
                    cacheSize,
                    _searchQuery.isNotEmpty,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Filter Dropdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildFilterAction(theme),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Chart
              SliverToBoxAdapter(
                child: _buildChartSection(
                  context,
                  theme,
                  topAppsForChart,
                  otherSizeForChart,
                  totalSize,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Search Bar (Moved Below Chart)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(theme),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _searchQuery.isEmpty
                              ? "HEAVIEST APPS"
                              : "SEARCH RESULTS",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      );
                    }
                    final appIndex = index - 1;
                    final app = validApps[appIndex];
                    final percent = app.size / (totalSize > 0 ? totalSize : 1);
                    final isTouched = appIndex == _touchedIndex;

                    return _buildAppItem(
                      context,
                      theme,
                      app,
                      percent,
                      appIndex,
                      isTouched,
                    );
                  }, childCount: validApps.length + 1),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return CustomScrollView(
      slivers: [
        const PremiumSliverAppBar(title: "Storage Insights"),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _buildSearchBar(theme),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(message, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Search storage...",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: theme.colorScheme.surface,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
              child: Icon(
                Icons.close,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatsCard(
    ThemeData theme,
    int total,
    int code,
    int data,
    int cache,
    bool isfiltered,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatBytes(total),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isfiltered ? "FILTERED SIZE" : "TOTAL CONSUMED",
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(theme, "App Code", code, Colors.blue),
              _buildStatItem(theme, "User Data", data, Colors.green),
              _buildStatItem(theme, "Cache", cache, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, int bytes, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, size: 8, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAction(ThemeData theme) {
    return PopupMenuButton<int>(
      initialValue: _showTopCount,
      onSelected: (value) => setState(() => _showTopCount = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 5, child: Text("Top 5 Apps")),
        const PopupMenuItem(value: 10, child: Text("Top 10 Apps")),
        const PopupMenuItem(value: 20, child: Text("Top 20 Apps")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Top $_showTopCount",
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    ThemeData theme,
    List<DeviceApp> topApps,
    int otherSize,
    int totalSize,
  ) {
    if (totalSize == 0) return const SizedBox();

    String centerTopText = "Total";
    String centerBottomText = _formatBytes(totalSize);

    if (_touchedIndex != -1 && _touchedIndex < topApps.length) {
      final app = topApps[_touchedIndex];
      final percentage = (app.size / totalSize) * 100;
      centerTopText = "${percentage.toStringAsFixed(1)}%";
      centerBottomText = app.appName;
    } else if (_touchedIndex == topApps.length && otherSize > 0) {
      final percentage = (otherSize / totalSize) * 100;
      centerTopText = "${percentage.toStringAsFixed(1)}%";
      centerBottomText = "Others";
    }

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    if (event is FlTapUpEvent && _touchedIndex != -1) {
                      setState(() => _touchedIndex = -1);
                    }
                    return;
                  }
                  final newIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (_touchedIndex != newIndex && newIndex >= 0) {
                    setState(() => _touchedIndex = newIndex);
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              sections: _generateSections(theme, topApps, otherSize),
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey("$_touchedIndex"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTopText,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      centerBottomText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    ThemeData theme,
    List<DeviceApp> apps,
    int otherSize,
  ) {
    List<PieChartSectionData> sections = [];
    final bool showBadges = apps.length <= 25;

    for (int i = 0; i < apps.length; i++) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final app = apps[i];
      final value = app.size.toDouble();

      final double normalizedIndex = i / (apps.isNotEmpty ? apps.length : 1);
      final double opacity = 0.9 - (normalizedIndex * 0.7);
      final Color color = theme.colorScheme.primary.withValues(
        alpha: opacity.clamp(0.15, 0.9),
      );

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: radius,
          badgeWidget: showBadges
              ? _AppIcon(app: app, size: isTouched ? 36 : 28, addBorder: true)
              : null,
          badgePositionPercentageOffset: 0.98,
          borderSide: isTouched
              ? BorderSide(color: theme.colorScheme.surface, width: 2)
              : BorderSide.none,
        ),
      );
    }

    if (otherSize > 0) {
      final isTouched = apps.length == _touchedIndex;
      sections.add(
        PieChartSectionData(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          value: otherSize.toDouble(),
          title: '',
          radius: isTouched ? 60.0 : 50.0,
          badgeWidget: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          badgePositionPercentageOffset: 0.98,
        ),
      );
    }

    return sections;
  }

  Widget _buildAppItem(
    BuildContext context,
    ThemeData theme,
    DeviceApp app,
    double percent,
    int index,
    bool isTouched,
  ) {
    final internalCache = app.cacheSize >= app.externalCacheSize
        ? app.cacheSize - app.externalCacheSize
        : app.cacheSize; // Safety check

    return GestureDetector(
      onTap: () => AppRouteFactory.toAppDetails(context, app),
      onTapDown: (_) => setState(() => _touchedIndex = index),
      onTapCancel: () => setState(() => _touchedIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTouched
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isTouched
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _AppIcon(app: app, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatBytes(app.size),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // MICRO DETAILS
            if (isTouched) ...[
              const SizedBox(height: 12),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),

              // First Row: Core Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMicroStat(
                    theme,
                    "Code & OBB",
                    app.appSize,
                  ), // OBB is in appSize
                  _buildMicroStat(theme, "User Data", app.dataSize),
                  _buildMicroStat(theme, "Total Cache", app.cacheSize),
                ],
              ),
              const SizedBox(height: 8),
              // Second Row: Cache Breakdown (The Unfiltered Truth)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSmallMicroStat(
                      theme,
                      "Internal Cache",
                      internalCache,
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                    _buildSmallMicroStat(
                      theme,
                      "External Cache",
                      app.externalCacheSize,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMicroStat(ThemeData theme, String label, int bytes) {
    return Column(
      children: [
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMicroStat(ThemeData theme, String label, int bytes) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        Text(
          _formatBytes(bytes),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(1)} ${suffixes[i]}";
  }
}

class _AppIcon extends StatelessWidget {
  final DeviceApp app;
  final double size;
  final bool addBorder;

  const _AppIcon({
    required this.app,
    required this.size,
    this.addBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: addBorder ? Border.all(color: Colors.white, width: 1.5) : null,
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
