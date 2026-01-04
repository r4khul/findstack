import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../scan/presentation/pages/scan_page.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with WidgetsBindingObserver {
  int _touchedIndex = -1;
  int _showTopCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh permission state when user returns from settings
      ref.invalidate(usagePermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: appsAsync.when(
        data: (apps) {
          final validApps = apps
              .where((a) => a.totalTimeInForeground > 0)
              .toList();

          final permissionAsync = ref.watch(usagePermissionProvider);
          final hasPermission = permissionAsync.value ?? false;

          if (validApps.isEmpty) {
            return CustomScrollView(
              slivers: [
                const PremiumSliverAppBar(title: "Usage Statistics"),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.4,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Premium Icon with Glow
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    (hasPermission
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error)
                                        .withOpacity(0.05),
                                border: Border.all(
                                  color:
                                      (hasPermission
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.error)
                                          .withOpacity(0.1),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color:
                                        (hasPermission
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.error)
                                            .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    hasPermission
                                        ? Icons.query_stats_rounded
                                        : Icons.shield_moon_rounded,
                                    size: 36,
                                    color: hasPermission
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Title & Description
                            Text(
                              hasPermission
                                  ? "No Insights Yet"
                                  : "Unlock Insights",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hasPermission
                                  ? "Deep scan required to analyze your usage patterns tailored to your lifestyle."
                                  : "Grant usage access to see exactly where your time goes. Your data stays 100% private on this device.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),
                            // Premium Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: () async {
                                  if (hasPermission) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ScanPage(),
                                      ),
                                    );
                                  } else {
                                    final repo = ref.read(
                                      deviceAppsRepositoryProvider,
                                    );
                                    await repo.requestUsagePermission();
                                    ref.invalidate(usagePermissionProvider);
                                  }
                                },
                                style:
                                    FilledButton.styleFrom(
                                      backgroundColor: hasPermission
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ).copyWith(
                                      overlayColor:
                                          WidgetStateProperty.resolveWith((
                                            states,
                                          ) {
                                            return Colors.white.withOpacity(
                                              0.1,
                                            );
                                          }),
                                    ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasPermission
                                          ? Icons.bolt_rounded
                                          : Icons
                                                .settings_accessibility_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hasPermission
                                          ? "Start Deep Analysis"
                                          : "Enable Access",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Optional: Secondary hint for scan
                            if (hasPermission)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  "Takes about 20 seconds",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          validApps.sort(
            (a, b) =>
                b.totalTimeInForeground.compareTo(a.totalTimeInForeground),
          );

          final totalUsage = validApps.fold<int>(
            0,
            (sum, app) => sum + app.totalTimeInForeground,
          );
          final topApps = validApps.take(_showTopCount).toList();
          final topUsage = topApps.fold<int>(
            0,
            (sum, app) => sum + app.totalTimeInForeground,
          );
          final otherUsage = totalUsage - topUsage;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const PremiumSliverAppBar(title: "Usage Statistics"),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Roast Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRoastSection(
                    theme,
                    Duration(milliseconds: totalUsage),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Filter Action
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFilterAction(theme),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Chart Section
              SliverToBoxAdapter(
                child: _buildChartSection(
                  context,
                  theme,
                  topApps,
                  otherUsage,
                  totalUsage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // App List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          "TOP CONTRIBUTORS",
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
                    final app = topApps[appIndex];
                    final percent = (app.totalTimeInForeground / totalUsage);
                    final isTouched = appIndex == _touchedIndex;
                    return _buildAppItem(
                      context,
                      theme,
                      app,
                      percent,
                      appIndex,
                      isTouched,
                    );
                  }, childCount: topApps.length + 1),
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

  Widget _buildFilterAction(ThemeData theme) {
    return PopupMenuButton<int>(
      initialValue: _showTopCount,
      onSelected: (value) {
        if (mounted) {
          setState(() => _showTopCount = value);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 5, child: Text("Top 5 Apps")),
        const PopupMenuItem(value: 10, child: Text("Top 10 Apps")),
        const PopupMenuItem(value: 20, child: Text("Top 20 Apps")),
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildRoastSection(ThemeData theme, Duration total) {
    String roast = "Ideally, you could have learnt a new language.";
    final hours = total.inHours;
    if (hours > 1000) {
      roast = "That's... a significant portion of your finite existence.";
    } else if (hours > 500) {
      roast = "You could have walked to Mordor and back.";
    } else if (hours > 100) {
      roast = "Think of the books you could have read.";
    } else if (hours > 24) {
      roast = "A whole day gone. Poof.";
    } else if (hours > 5) {
      roast = "Productivity taking a hit, isn't it?";
    } else {
      roast = "Surprisingly productive... or just installed?";
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.02),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _formatDurationLarge(total),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "LIFESPAN CONSUMED",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              roast,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    ThemeData theme,
    List<DeviceApp> displayApps,
    int otherUsage,
    int totalUsage,
  ) {
    if (totalUsage == 0) return const SizedBox();

    String centerTopText = "Total";
    String centerBottomText = _formatDuration(
      Duration(milliseconds: totalUsage),
    );

    if (_touchedIndex != -1 && _touchedIndex < displayApps.length) {
      final app = displayApps[_touchedIndex];
      final percentage = (app.totalTimeInForeground / totalUsage) * 100;
      centerTopText = "${percentage.toStringAsFixed(1)}%";
      centerBottomText = app.appName;
    } else if (_touchedIndex == displayApps.length && otherUsage > 0) {
      final percentage = (otherUsage / totalUsage) * 100;
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
                      if (mounted) {
                        setState(() => _touchedIndex = -1);
                      }
                    }
                    return;
                  }
                  final newIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (_touchedIndex != newIndex && newIndex >= 0) {
                    if (mounted) {
                      setState(() => _touchedIndex = newIndex);
                    }
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              sections: _generateSections(
                context,
                theme,
                displayApps,
                otherUsage,
              ),
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(
                      Tween(
                        begin: 0.9,
                        end: 1.0,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey("$_touchedIndex"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTopText,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      centerBottomText,
                      textAlign: TextAlign.center,
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
    BuildContext context,
    ThemeData theme,
    List<DeviceApp> displayApps,
    int otherUsage,
  ) {
    List<PieChartSectionData> sections = [];
    // Allow badges for up to 25 items (covers Top 20)
    final bool showBadges = displayApps.length <= 25;

    for (int i = 0; i < displayApps.length; i++) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final app = displayApps[i];
      final value = app.totalTimeInForeground.toDouble();

      // Monochrome Palette (Strictly no colors)
      // Smooth gradient of opacity for professional look
      final double normalizedIndex =
          i / (displayApps.isNotEmpty ? displayApps.length : 1);
      final double opacity = 0.9 - (normalizedIndex * 0.7);
      final Color color = theme.colorScheme.primary.withValues(
        alpha: opacity.clamp(0.15, 0.9),
      );

      // Dynamically size badges to prevent overcrowding
      final double badgeSize = isTouched
          ? 36.0
          : (displayApps.length > 10 ? 20.0 : 28.0);

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: radius,
          badgeWidget: showBadges
              ? _AppIcon(app: app, size: badgeSize, addBorder: true)
              : null,
          badgePositionPercentageOffset: 0.98,
          borderSide: isTouched
              ? BorderSide(color: theme.colorScheme.surface, width: 2)
              : const BorderSide(color: Colors.transparent),
        ),
      );
    }

    if (otherUsage > 0) {
      final isTouched = displayApps.length == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      sections.add(
        PieChartSectionData(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          value: otherUsage.toDouble(),
          title: '',
          radius: radius,
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
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _navigateToApp(context, app),
        onTapDown: (_) {
          if (mounted) {
            setState(() => _touchedIndex = index);
          }
        },
        onTapCancel: () {
          if (mounted) {
            setState(() => _touchedIndex = -1);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
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
            boxShadow: isTouched
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Hero(
                tag: app.packageName,
                transitionOnUserGestures: true,
                createRectTween: (begin, end) {
                  return MaterialRectCenterArcTween(begin: begin, end: end);
                },
                flightShuttleBuilder:
                    (
                      flightContext,
                      animation,
                      flightDirection,
                      fromHeroContext,
                      toHeroContext,
                    ) {
                      // Optimization: Remove expensive blur/shadow animations.
                      // Just use a clean, static lifted state to prevent jitter.
                      return Material(
                        type: MaterialType.transparency,
                        child: toHeroContext.widget,
                      );
                    },
                child: _AppIcon(app: app, size: 48),
              ),
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
                          "${(percent * 100).toStringAsFixed(1)}%",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Monochrome Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 500),
                          widthFactor: percent,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary, // Monochrome
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDuration(
                        Duration(milliseconds: app.totalTimeInForeground),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    } else {
      return "${duration.inMinutes}m";
    }
  }

  String _formatDurationLarge(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes % 60}m";
    return "${d.inMinutes}m";
  }

  void _navigateToApp(BuildContext context, DeviceApp app) {
    // Use centralized navigation for consistent premium transitions
    AppRouteFactory.toAppDetails(context, app);
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
        boxShadow: addBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: app.icon != null
            ? Image.memory(
                app.icon!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.android, size: 16),
              )
            : const Icon(Icons.android, size: 16),
      ),
    );
  }
}
