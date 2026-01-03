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
                    _buildNativeLibsSection(theme, isDark),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Activity"),
        const SizedBox(height: 16),
        Container(
          height: 320, // Increased height for UsageChart
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
          "No usage recorded in last year",
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      );
    }
    // High-performance interactive chart
    final isDark = theme.brightness == Brightness.dark;
    return UsageChart(history: history, theme: theme, isDark: isDark);
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

  Widget _buildNativeLibsSection(ThemeData theme, bool isDark) {
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

  Widget _buildDeepInsights(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Storage & Paths"),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final packages = _detectPackages();
    if (packages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Detected Packages"),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packages.values.map((pkg) {
            return Material(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$pkg Detected using heuristics'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.extension,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          pkg,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, String> _detectPackages() {
    final Map<String, String> detected = {};

    void check(String text, String keyword, String pkgName) {
      if (text.toLowerCase().contains(keyword.toLowerCase()))
        detected[pkgName] = pkgName;
    }

    final allComponents = [...app.services, ...app.receivers, ...app.providers];

    for (var s in allComponents) {
      check(s, 'com.google.firebase', 'Firebase Core');
      check(s, 'com.google.android.gms.ads', 'Google Mobile Ads');
      check(s, 'com.google.android.gms.maps', 'Google Maps');
      check(s, 'com.facebook', 'Facebook SDK');
      check(s, 'com.amazonaws', 'AWS Amplify');
      check(s, 'androidx.work', 'WorkManager');
      check(s, 'androidx.room', 'Room Database');
      check(s, 'com.squareup.picasso', 'Picasso');
      check(s, 'com.bumptech.glide', 'Glide');
      check(s, 'retrofit', 'Retrofit');
      check(s, 'okhttp', 'OkHttp');
      check(s, 'coil', 'Coil');
      check(s, 'sentry', 'Sentry');
      check(s, 'crashlytics', 'Crashlytics');
      check(s, 'onesignal', 'OneSignal');
      check(s, 'stripe', 'Stripe');
      check(s, 'razorpay', 'Razorpay');
      check(s, 'zoom', 'Zoom SDK');
      check(s, 'twilio', 'Twilio');
    }

    for (var lib in app.nativeLibraries) {
      check(lib, 'mapbox', 'Mapbox');
      check(lib, 'realm', 'Realm');
      check(lib, 'reanimated', 'Reanimated');
      check(lib, 'hermes', 'Hermes Engine');
      check(lib, 'skia', 'Skia');
      check(lib, 'flipper', 'Flipper');
    }

    return detected;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}
