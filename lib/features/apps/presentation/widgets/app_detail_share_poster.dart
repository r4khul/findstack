import 'package:flutter/material.dart';
import '../../domain/entities/device_app.dart';

/// A shareable poster for app details - crisp, viral-worthy snapshot
class AppDetailSharePoster extends StatelessWidget {
  final DeviceApp app;

  const AppDetailSharePoster({super.key, required this.app});

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
          // Header with Branding
          Row(
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
              // Brand Logo
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
          ),

          const SizedBox(height: 32),

          // App Icon + Name Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // App Icon
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
                // App Name & Stack
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
          ),

          const SizedBox(height: 24),

          // Quick Stats Grid
          Row(
            children: [
              _buildStatCard("VERSION", app.version),
              const SizedBox(width: 12),
              _buildStatCard(
                "SDK",
                "${app.minSdkVersion} → ${app.targetSdkVersion}",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard("USAGE", usageString),
              const SizedBox(width: 12),
              _buildStatCard("INSTALLED", "$daysSinceInstall days ago"),
            ],
          ),

          const SizedBox(height: 24),

          // Deep Insights
          Container(
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
                _buildInsightRow("Size on Device", _formatBytes(app.size)),
                if (app.installerStore != 'Unknown')
                  _buildInsightRow(
                    "Source",
                    _formatInstallerName(app.installerStore),
                  ),
                if (app.techVersions.isNotEmpty)
                  ...app.techVersions.entries
                      .take(2)
                      .map((e) => _buildInsightRow("${e.key}", e.value)),
                if (app.splitApks.isNotEmpty)
                  _buildInsightRow(
                    "Split APKs",
                    "${app.splitApks.length} modules",
                  ),
                _buildInsightRow(
                  "Components",
                  "${app.activitiesCount + app.servicesCount + app.receiversCount + app.providersCount} total",
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
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

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
