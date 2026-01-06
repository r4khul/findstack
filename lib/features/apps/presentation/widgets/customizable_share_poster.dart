import 'package:flutter/material.dart';
import '../../domain/entities/device_app.dart';
import 'share_options_config.dart';

/// A customizable shareable poster for app details.
/// Optimized with RepaintBoundary wrapping and minimal rebuilds.
class CustomizableSharePoster extends StatelessWidget {
  final DeviceApp app;
  final ShareOptionsConfig config;

  const CustomizableSharePoster({
    super.key,
    required this.app,
    required this.config,
  });

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Branding (always visible)
          const _PosterHeader(),

          const SizedBox(height: 32),

          // App Icon + Name Hero Section (always visible)
          _AppHeroSection(app: app),

          const SizedBox(height: 24),

          // Quick Stats Grid (conditional)
          if (config.showVersion ||
              config.showSdk ||
              config.showUsage ||
              config.showInstallDate)
            _buildStatsGrid(config, usageString, daysSinceInstall),

          // Deep Insights (conditional)
          if (insightItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            _DeepInsightsSection(items: insightItems),
          ],

          const SizedBox(height: 32),

          // Footer (always visible)
          const _PosterFooter(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    ShareOptionsConfig config,
    String usageString,
    int daysSinceInstall,
  ) {
    final row1 = <Widget>[];
    final row2 = <Widget>[];

    if (config.showVersion) {
      row1.add(_StatCard(label: "VERSION", value: app.version));
    }
    if (config.showSdk) {
      if (row1.isNotEmpty) row1.add(const SizedBox(width: 12));
      row1.add(
        _StatCard(
          label: "SDK",
          value: "${app.minSdkVersion} → ${app.targetSdkVersion}",
        ),
      );
    }
    if (config.showUsage) {
      row2.add(_StatCard(label: "USAGE", value: usageString));
    }
    if (config.showInstallDate) {
      if (row2.isNotEmpty) row2.add(const SizedBox(width: 12));
      row2.add(
        _StatCard(label: "INSTALLED", value: "$daysSinceInstall days ago"),
      );
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

// ========== Extracted Stateless Components for Performance ==========

class _PosterHeader extends StatelessWidget {
  const _PosterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "APP EXPOSED",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Unfiltered Truth",
              style: TextStyle(
                color: Colors.white,
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
              colors: [Colors.white, Colors.white.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Image.asset(
            'assets/icons/black-unfilter-nobg.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _AppHeroSection extends StatelessWidget {
  final DeviceApp app;

  const _AppHeroSection({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.1),
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
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: _getStackColor(app.stack).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStackColor(app.stack).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    app.stack,
                    style: TextStyle(
                      color: _getStackColor(app.stack),
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem {
  final String label;
  final String value;
  const _InsightItem(this.label, this.value);
}

class _DeepInsightsSection extends StatelessWidget {
  final List<_InsightItem> items;

  const _DeepInsightsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DEEP INSIGHTS",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
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
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: Colors.white,
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
}

class _PosterFooter extends StatelessWidget {
  const _PosterFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            "Analyzed by Unfilter",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
