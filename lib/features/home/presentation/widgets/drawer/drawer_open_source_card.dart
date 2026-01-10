import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/github_stars_provider.dart';

/// GitHub open source card widget for the drawer.
///
/// Displays a tappable card that links to the project's GitHub repository.
/// Shows the current star count fetched from the GitHub API.
class DrawerOpenSourceCard extends ConsumerWidget {
  /// Creates a drawer open source card.
  const DrawerOpenSourceCard({super.key});

  /// GitHub repository URL.
  static const _repoUrl = 'https://github.com/r4khul/unfilter';

  /// GitHub star icon color (gold).
  static const _starColor = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final starsAsync = ref.watch(githubStarsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchGitHub,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildGitHubIcon(theme),
                const SizedBox(width: 16),
                Expanded(child: _buildTextContent(theme)),
                _buildStarsBadge(theme, starsAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        'assets/vectors/icon_github.svg',
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Source',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          'Give a Star on Github',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsBadge(ThemeData theme, AsyncValue<int> starsAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _starColor, size: 14),
          const SizedBox(width: 4),
          starsAsync.when(
            data: (stars) => Text(
              '$stars',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            loading: () => const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            error: (_, __) => const Text('-'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGitHub() async {
    final url = Uri.parse(_repoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
