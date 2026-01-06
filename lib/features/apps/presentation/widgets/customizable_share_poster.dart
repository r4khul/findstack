import 'package:flutter/material.dart';
import '../../domain/entities/device_app.dart';
import 'share_options_config.dart';

/// A customizable shareable poster for app details.
/// Supports both light and dark themes based on config.
class CustomizableSharePoster extends StatelessWidget {
  final DeviceApp app;
  final ShareOptionsConfig config;

  const CustomizableSharePoster({
    super.key,
    required this.app,
    required this.config,
  });

  // Theme colors based on posterDarkMode
  Color get _bgStart =>
      config.posterDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);
  Color get _bgEnd =>
      config.posterDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color get _textPrimary =>
      config.posterDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get _textSecondary => config.posterDarkMode
      ? Colors.white.withOpacity(0.5)
      : const Color(0xFF1A1A1A).withOpacity(0.5);
  Color get _textTertiary => config.posterDarkMode
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF1A1A1A).withOpacity(0.6);
  Color get _cardBg => config.posterDarkMode
      ? Colors.white.withOpacity(0.05)
      : Colors.black.withOpacity(0.03);
  Color get _cardBorder => config.posterDarkMode
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.08);
  Color get _insightBg => config.posterDarkMode
      ? Colors.white.withOpacity(0.03)
      : Colors.black.withOpacity(0.02);

  @override
  Widget build(BuildContext context) {
    // Calculate usage stats
    final totalDuration = Duration(milliseconds: app.totalTimeInForeground);
    final usageHours = totalDuration.inHours;
    final usageMinutes = totalDuration.inMinutes % 60;
    final usageString = usageHours > 0
        ? "${usageHours}h ${usageMinutes}m"
        : "${usageMinutes}m";

    final daysSinceInstall = DateTime.now().difference(app.installDate).inDays;

    // Collect visible insight items
    final insightItems = <_InsightItem>[];
    if (config.showSize) {
      insightItems.add(_InsightItem("Size on Device", _formatBytes(app.size)));
    }
    if (config.showSource && app.installerStore != 'Unknown') {
      insightItems.add(
        _InsightItem("Source", _formatInstallerName(app.installerStore)),
      );
    }
    if (config.showTechVersions && app.techVersions.isNotEmpty) {
      for (final entry in app.techVersions.entries.take(2)) {
        insightItems.add(_InsightItem(entry.key, entry.value));
      }
    }
    if (config.showSplitApks && app.splitApks.isNotEmpty) {
      insightItems.add(
        _InsightItem("Split APKs", "${app.splitApks.length} modules"),
      );
    }
    if (config.showComponents) {
      final total =
          app.activitiesCount +
          app.servicesCount +
          app.receiversCount +
          app.providersCount;
      if (total > 0) {
        insightItems.add(_InsightItem("Components", "$total total"));
      }
    }

    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgStart, _bgEnd],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Branding
          _buildHeader(),

          const SizedBox(height: 32),

          // App Icon + Name Hero Section
          _buildHeroSection(),

          const SizedBox(height: 24),

          // Quick Stats Grid (conditional)
          if (config.showVersion ||
              config.showSdk ||
              config.showUsage ||
              config.showInstallDate)
            _buildStatsGrid(usageString, daysSinceInstall),

          // Deep Insights (conditional)
          if (insightItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildInsightsSection(insightItems),
          ],

          const SizedBox(height: 32),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final logoAsset = config.posterDarkMode
        ? 'assets/icons/black-unfilter-nobg.png'
        : 'assets/icons/white-unfilter-nobg.png';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "APP EXPOSED",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Unfiltered Truth",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: config.posterDarkMode
                  ? [Colors.white, Colors.white.withOpacity(0.5)]
                  : [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF1A1A1A).withOpacity(0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Image.asset(logoAsset, fit: BoxFit.contain),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final stackColor = _getStackColor(app.stack);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _cardBg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: app.icon != null
                  ? Image.memory(app.icon!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        app.appName.isNotEmpty
                            ? app.appName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stackColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stackColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    app.stack,
                    style: TextStyle(
                      color: stackColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String usageString, int daysSinceInstall) {
    final row1 = <Widget>[];
    final row2 = <Widget>[];

    if (config.showVersion) {
      row1.add(_buildStatCard("VERSION", app.version));
    }
    if (config.showSdk) {
      if (row1.isNotEmpty) row1.add(const SizedBox(width: 12));
      row1.add(
        _buildStatCard("SDK", "${app.minSdkVersion} → ${app.targetSdkVersion}"),
      );
    }
    if (config.showUsage) {
      row2.add(_buildStatCard("USAGE", usageString));
    }
    if (config.showInstallDate) {
      if (row2.isNotEmpty) row2.add(const SizedBox(width: 12));
      row2.add(_buildStatCard("INSTALLED", "$daysSinceInstall days ago"));
    }

    return Column(
      children: [
        if (row1.isNotEmpty)
          Row(
            children: row1.length == 1 ? [Expanded(child: row1.first)] : row1,
          ),
        if (row1.isNotEmpty && row2.isNotEmpty) const SizedBox(height: 12),
        if (row2.isNotEmpty)
          Row(
            children: row2.length == 1 ? [Expanded(child: row2.first)] : row2,
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(List<_InsightItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _insightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DEEP INSIGHTS",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(color: _textTertiary, fontSize: 13),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFooter() {
    return Column(
      children: [
        // Branding
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: _textTertiary, size: 16),
            const SizedBox(width: 8),
            Text(
              "Analyzed by Unfilter",
              style: TextStyle(
                color: _textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Disclaimer
        Text(
          "Detection based on primary libraries · Apps may use hybrid frameworks",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondary.withOpacity(0.6),
            fontSize: 9,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Color _getStackColor(String stack) {
    switch (stack.toLowerCase()) {
      case 'flutter':
        return const Color(0xFF5CACEE);
      case 'react native':
        return const Color(0xFF61DAFB);
      case 'kotlin':
      case 'jetpack compose':
      case 'jetpack':
        return const Color(0xFFB388FF);
      case 'java':
        return const Color(0xFFEF9A9A);
      default:
        return const Color(0xFF81C784);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  String _formatInstallerName(String raw) {
    if (raw.contains('vending')) return 'Play Store';
    if (raw.contains('xiaomi') || raw.contains('miui')) return 'Xiaomi Store';
    if (raw.contains('samsung')) return 'Galaxy Store';
    if (raw.contains('amazon')) return 'Amazon Appstore';
    if (raw.contains('huawei')) return 'AppGallery';
    if (raw.contains('oppo')) return 'OPPO Store';
    if (raw.contains('vivo')) return 'Vivo Store';
    if (raw.contains('packageinstaller') || raw.contains('shell')) {
      return 'Manual Install';
    }
    return raw.split('.').last.replaceAll('installer', '').capitalize();
  }
}

class _InsightItem {
  final String label;
  final String value;
  const _InsightItem(this.label, this.value);
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
