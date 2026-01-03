import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../domain/entities/app_usage_point.dart';
import '../../domain/entities/device_app.dart';
import '../providers/app_detail_provider.dart';
import '../widgets/usage_chart.dart';

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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PremiumSliverAppBar(
            title: "App Details",
            onResync: () {
              // ignore: unused_result
              ref.refresh(appUsageHistoryProvider(app.packageName));
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAppHeader(context, theme, isDark),
                  const SizedBox(height: 32),
                  _buildStatRow(theme, isDark),
                  const SizedBox(height: 32),
                  _buildUsageSection(theme, usageHistoryAsync, isDark),
                  const SizedBox(height: 32),
                  _buildInfoSection(context, theme, isDark),
                  const SizedBox(height: 32),
                  _buildDeepInsights(context, theme, isDark),
                  const SizedBox(height: 32),
                  if (app.nativeLibraries.isNotEmpty) ...[
                    _buildNativeLibsSection(context, theme, isDark),
                    const SizedBox(height: 32),
                  ],
                  _buildDeveloperSection(context, theme, isDark),
                  const SizedBox(height: 32),
                  if (app.permissions.isNotEmpty) ...[
                    _buildPermissionsSection(context, theme, isDark),
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
    Color stackColor;
    switch (app.stack.toLowerCase()) {
      case 'flutter':
        stackColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF02569B);
        break;
      case 'react native':
        stackColor = isDark ? const Color(0xFF61DAFB) : const Color(0xFF0D47A1);
        break;
      case 'kotlin':
        stackColor = isDark ? const Color(0xFF7F52FF) : const Color(0xFF4800D6);
        break;
      case 'java':
        stackColor = isDark ? const Color(0xFFF44336) : const Color(0xFFB71C1C);
        break;
      case 'swift':
        stackColor = isDark ? const Color(0xFFFF9800) : const Color(0xFFE65100);
        break;
      case 'ionic':
        stackColor = isDark ? const Color(0xFF3880FF) : const Color(0xFF3880FF);
        break;
      case 'xamarin':
        stackColor = isDark ? const Color(0xFF3498DB) : const Color(0xFF2980B9);
        break;
      case 'unity':
        stackColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
        break;
      case 'godot':
        stackColor = isDark ? const Color(0xFF478CBF) : const Color(0xFF336699);
        break;
      default:
        stackColor = const Color(0xFF3DDC84); // Android Green
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            app.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            app.packageName,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: stackColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: stackColor.withOpacity(0.2), width: 0.8),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
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
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(
    ThemeData theme,
    AsyncValue<List<AppUsagePoint>> historyAsync,
    bool isDark,
  ) {
    // Calculate total duration string
    final totalDuration = Duration(milliseconds: app.totalTimeInForeground);
    String totalUsageStr;
    if (totalDuration.inHours > 0) {
      totalUsageStr =
          "${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m";
    } else {
      totalUsageStr = "${totalDuration.inMinutes}m";
    }

    final daysSinceInstall = DateTime.now().difference(app.installDate).inDays;
    final installDateStr = DateFormat('MMM d, y').format(app.installDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(theme, "Activity"),
            if (app.totalTimeInForeground > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalUsageStr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (app.totalTimeInForeground > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              "Used for $totalUsageStr since installed on $installDateStr ($daysSinceInstall days ago)",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (history) {
            final hasUsage =
                app.totalTimeInForeground > 0 ||
                (history.isNotEmpty &&
                    history.any((h) => h.usage.inSeconds > 0));

            final containerHeight = hasUsage ? 360.0 : 130.0;

            return Container(
              height: containerHeight,
              width: double.infinity,
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
              child: hasUsage
                  ? UsageChart(history: history, theme: theme, isDark: isDark)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            history.isEmpty
                                ? "No recent activity"
                                : "No adequate data to plot chart",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
          loading: () => Container(
            height: 340,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
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

  Widget _buildInfoSection(BuildContext context, ThemeData theme, bool isDark) {
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
                context,
                theme,
                "Package",
                app.packageName,
                showDivider: true,
              ),
              _buildDetailItem(
                context,
                theme,
                "UID",
                app.uid.toString(),
                showDivider: true,
              ),
              _buildDetailItem(
                context,
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
    BuildContext context,
    ThemeData theme,
    String label,
    String value, {
    bool showDivider = false,
  }) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 5,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildDeepInsights(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Deep Insights"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              if (app.installerStore != 'Unknown') ...[
                _buildDetailItem(
                  context,
                  theme,
                  "Installer",
                  _formatInstallerName(app.installerStore),
                  showDivider: true,
                ),
              ],
              if (app.techVersions.isNotEmpty) ...[
                for (final entry in app.techVersions.entries)
                  _buildDetailItem(
                    context,
                    theme,
                    "${entry.key} Version",
                    entry.value,
                    showDivider: true,
                  ),
              ],
              if (app.kotlinVersion != null &&
                  !app.techVersions.containsKey('Kotlin')) ...[
                _buildDetailItem(
                  context,
                  theme,
                  "Kotlin Version",
                  app.kotlinVersion!,
                  showDivider: true,
                ),
              ],
              _buildDetailItem(
                context,
                theme,
                "Min SDK",
                "${app.minSdkVersion} (${_sdkVersionName(app.minSdkVersion)})",
                showDivider: true,
              ),
              _buildDetailItem(
                context,
                theme,
                "Target SDK",
                "${app.targetSdkVersion} (${_sdkVersionName(app.targetSdkVersion)})",
                showDivider: true,
              ),
              if (app.signingSha1 != null)
                _buildDetailItem(
                  context,
                  theme,
                  "Signature (SHA-1)",
                  app.signingSha1!,
                  showDivider: true,
                ),
              if (app.splitApks.isNotEmpty)
                _buildDetailItem(
                  context,
                  theme,
                  "Split APKs",
                  "${app.splitApks.length} splits",
                  showDivider: true,
                ),
              _buildDetailItem(
                context,
                theme,
                "App Size",
                _formatBytes(app.size),
                showDivider: true,
              ),
              _buildDetailItem(
                context,
                theme,
                "APK Path",
                app.apkPath,
                showDivider: true,
              ),
              _buildDetailItem(context, theme, "Data Dir", app.dataDir),

              const SizedBox(height: 24),
              // Component Counts Grid
              Row(
                children: [
                  _buildComponentCount(
                    theme,
                    "Activities",
                    app.activitiesCount,
                  ),
                  const SizedBox(width: 12),
                  _buildComponentCount(theme, "Services", app.servicesCount),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildComponentCount(theme, "Receivers", app.receiversCount),
                  const SizedBox(width: 12),
                  _buildComponentCount(theme, "Providers", app.providersCount),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComponentCount(ThemeData theme, String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeLibsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    if (app.nativeLibraries.length > 6) {
      const int maxVisible = 5;
      final displayedLibs = app.nativeLibraries.take(maxVisible).toList();
      final remainingCount = app.nativeLibraries.length - maxVisible;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, "Native Libraries"),
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
              children: [
                ...displayedLibs.map((lib) => _buildNativeLibRow(theme, lib)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAllNativeLibs(context, theme),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      "View $remainingCount More",
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Native Libraries"),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: app.nativeLibraries
              .map(
                (lib) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_system_daydream_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          lib,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNativeLibRow(ThemeData theme, String lib) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.settings_system_daydream_rounded,
            size: 18,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lib,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllNativeLibs(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      "Native Libraries",
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: app.nativeLibraries.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        Icons.settings_system_daydream_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        app.nativeLibraries[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final packages = _detectPackages();
    if (packages.isEmpty) return const SizedBox.shrink();

    if (packages.length > 6) {
      const int maxVisible = 5;
      final displayedPackages = packages.values.take(maxVisible).toList();
      final remainingCount = packages.length - maxVisible;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, "Detected Packages"),
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
              children: [
                ...displayedPackages.map((pkg) => _buildPackageRow(theme, pkg)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAllPackages(
                      context,
                      theme,
                      packages.values.toList(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      "View $remainingCount More",
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Detected Packages"),
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
            children: packages.values
                .map((pkg) => _buildPackageRow(theme, pkg))
                .toList(),
          ),
        ),
      ],
    );
  }

  Map<String, String> _detectPackages() {
    final Map<String, String> detected = {};
    for (final lib in app.nativeLibraries) {
      if (lib.contains("stripe"))
        detected["Stripe"] = "Payment Gateway";
      else if (lib.contains("mapbox"))
        detected["Mapbox"] = "Maps & Location";
      else if (lib.contains("realm"))
        detected["Realm"] = "Database";
      else if (lib.contains("firebase"))
        detected["Firebase"] = "Backend/Analytics";
      else if (lib.contains("appwrite"))
        detected["Appwrite"] = "Backend";
      else if (lib.contains("supabase"))
        detected["Supabase"] = "Backend";
      else if (lib.contains("sentry"))
        detected["Sentry"] = "Crash Reporting";
    }
    return detected;
  }

  Widget _buildPackageRow(ThemeData theme, String package) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.extension_rounded,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Text(
            package,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllPackages(
    BuildContext context,
    ThemeData theme,
    List<String> packages,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      "Detected Packages",
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        Icons.extension_rounded,
                        color: theme.colorScheme.secondary,
                      ),
                      title: Text(
                        packages[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    const int maxVisible = 5;
    final displayedPermissions = app.permissions.take(maxVisible).toList();
    final remainingCount = app.permissions.length - maxVisible;

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
            children: [
              ...displayedPermissions.map((p) => _buildPermissionRow(theme, p)),
              if (remainingCount > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAllPermissions(context, theme),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      "View $remainingCount More",
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRow(ThemeData theme, String permission) {
    return Padding(
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
              permission.split('.').last,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllPermissions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text("Permissions", style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: app.permissions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        app.permissions[index].split('.').last,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        app.permissions[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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

  String _formatInstallerName(String pkg) {
    if (pkg.contains("vending")) return "Google Play Store";
    if (pkg.contains("amazon")) return "Amazon Appstore";
    if (pkg.contains("packageinstaller")) return "Manual Install (APK)";
    return pkg;
  }

  String _sdkVersionName(int sdk) {
    switch (sdk) {
      case 34:
        return "Android 14";
      case 33:
        return "Android 13";
      case 32:
        return "Android 12L";
      case 31:
        return "Android 12";
      case 30:
        return "Android 11";
      case 29:
        return "Android 10";
      case 28:
        return "Pie";
      case 27:
        return "Oreo 8.1";
      case 26:
        return "Oreo 8.0";
      case 25:
        return "Nougat 7.1";
      case 24:
        return "Nougat 7.0";
      case 23:
        return "Marshmallow";
      case 22:
        return "Lollipop 5.1";
      case 21:
        return "Lollipop 5.0";
      default:
        return "API $sdk";
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
