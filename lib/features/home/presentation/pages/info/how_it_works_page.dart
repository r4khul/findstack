import 'package:flutter/material.dart';

import '../../widgets/external_link_tile.dart';
import '../../widgets/premium_sliver_app_bar.dart';

/// How It Works page explaining the app's technology.
///
/// Displays a step-by-step explanation of how the app analyzes
/// installed applications to detect their tech stacks.
class HowItWorksPage extends StatelessWidget {
  /// Creates the how it works page.
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(title: 'How it works'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildIntroText(theme),
                  const SizedBox(height: 20),
                  const ExternalLinkTile(
                    label: 'Open Source',
                    value: 'View',
                    url: 'https://github.com/r4khul/unfilter',
                  ),
                  const SizedBox(height: 30),
                  const _StepCard(
                    step: '01',
                    title: 'Deep Scan',
                    description:
                        "We dig through each app's package info and native "
                        "libraries sitting right on your phone. Nothing leaves "
                        "your device.",
                    icon: Icons.radar_rounded,
                  ),
                  const _StepCard(
                    step: '02',
                    title: 'Signature Matching',
                    description:
                        'We run those files against a local database of 50+ '
                        'frameworks—Flutter, React Native, Unity, you name '
                        'it—to find matches.',
                    icon: Icons.fingerprint_rounded,
                  ),
                  const _StepCard(
                    step: '03',
                    title: 'Zero Cloud',
                    description:
                        'Start to finish, every scan happens locally. Your app '
                        "data stays on your phone—we literally can't see it.",
                    icon: Icons.cloud_off_rounded,
                    isLast: true,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      'Under\nthe Hood',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.0,
      ),
    );
  }

  Widget _buildIntroText(ThemeData theme) {
    return Text(
      'No decompiling. No uploads. Just smart static analysis that reads '
      "what's already there and tells you exactly what an app is built with.",
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        height: 1.5,
        fontSize: 16,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Private Widgets
// -----------------------------------------------------------------------------

/// Step card widget with timeline indicator.
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeline(theme),
          const SizedBox(width: 20),
          Expanded(child: _buildCard(theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    return Column(
      children: [
        _buildStepIndicator(theme),
        if (!isLast) _buildTimelineLine(theme),
      ],
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Center(
        child: Text(
          step,
          style:
              theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ) ??
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTimelineLine(ThemeData theme) {
    return Expanded(
      child: Container(
        width: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
