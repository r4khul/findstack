import 'package:flutter/material.dart';

import '../../../apps/domain/entities/device_app.dart';

/// Share poster widget for usage statistics.
///
/// Renders a visually appealing poster image showing:
/// - Total screen time
/// - Top apps by usage
/// - Optional "roast" content showing lifespan consumed
///
/// This widget is designed for screenshot/export and uses a fixed
/// width for consistent rendering across devices.
class UsageStatsSharePoster extends StatelessWidget {
  /// Top apps sorted by usage time.
  final List<DeviceApp> topApps;

  /// Total usage duration to display.
  final Duration totalUsage;

  /// Date string to show on the poster.
  final String date;

  /// Optional roast text about lifespan consumed.
  final String? roastContent;

  /// Creates a usage stats share poster.
  const UsageStatsSharePoster({
    super.key,
    required this.topApps,
    required this.totalUsage,
    required this.date,
    this.roastContent,
  });

  /// Fixed poster width for consistent export sizing.
  static const double _posterWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _posterWidth,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A), // Dark Grey
            Color(0xFF000000), // Black
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PosterHeader(),
          const SizedBox(height: 40),
          _HeroStatCard(totalUsage: totalUsage, date: date),
          if (roastContent != null) ...[
            const SizedBox(height: 32),
            _RoastCard(content: roastContent!),
          ],
          const SizedBox(height: 40),
          _TopAppsSection(topApps: topApps, totalUsage: totalUsage),
          const SizedBox(height: 40),
          const _PosterFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Private Widgets
// -----------------------------------------------------------------------------

/// Header section with branding.
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
              'UNFILTERED',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Digital Footprint',
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

/// Hero stat card showing total screen time.
class _HeroStatCard extends StatelessWidget {
  final Duration totalUsage;
  final String date;

  const _HeroStatCard({required this.totalUsage, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL SCREEN TIME',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(totalUsage),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Roast card showing lifespan consumed message.
class _RoastCard extends StatelessWidget {
  final String content;

  const _RoastCard({required this.content});

  static const _roastColor = Color(0xFFB00020);
  static const _roastAccent = Color(0xFFFF5252);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roastColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _roastColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'LIFESPAN CONSUMED',
            style: TextStyle(
              color: _roastAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section showing top apps by usage.
class _TopAppsSection extends StatelessWidget {
  final List<DeviceApp> topApps;
  final Duration totalUsage;

  const _TopAppsSection({required this.topApps, required this.totalUsage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP DISTRACTIONS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...topApps.map((app) => _AppUsageRow(app: app, totalUsage: totalUsage)),
      ],
    );
  }
}

/// Single app row showing usage details.
class _AppUsageRow extends StatelessWidget {
  final DeviceApp app;
  final Duration totalUsage;

  const _AppUsageRow({required this.app, required this.totalUsage});

  @override
  Widget build(BuildContext context) {
    final totalMs = totalUsage.inMilliseconds;
    final percent = totalMs > 0 ? (app.totalTimeInForeground / totalMs) : 0.0;

    final appDuration = Duration(milliseconds: app.totalTimeInForeground);
    final timeString = _formatAppDuration(appDuration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAppIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppInfoRow(timeString, percent),
                const SizedBox(height: 6),
                _buildProgressBar(percent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: app.icon != null
            ? Image.memory(app.icon!, fit: BoxFit.cover)
            : const Icon(Icons.android, color: Colors.white),
      ),
    );
  }

  Widget _buildAppInfoRow(String timeString, double percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            app.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          timeString,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percent * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 4,
        backgroundColor: Colors.white.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  String _formatAppDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Footer with signature.
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
            'Analyzed by Unfilter',
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
