import 'package:flutter/material.dart';

import '../scan_button.dart';
import '../settings_menu.dart';

/// Top app bar section with logo/title and action buttons.
///
/// Handles the transition between expanded title and collapsed logo view.
/// Contains the scan button and settings menu.
class HomeTopAppBar extends StatelessWidget {
  /// App count to display in collapsed state.
  final int appCount;

  /// Animation progress value (0.0 to 1.0) for title/logo transition.
  final double transitionProgress;

  /// Creates a home top app bar.
  const HomeTopAppBar({
    super.key,
    required this.appCount,
    required this.transitionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 56, // Standard toolbar height
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _buildTitleLogoTransition(theme)),
            const ScanButton(),
            const SizedBox(width: 4),
            const SettingsMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleLogoTransition(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Expanded Title (Exiting)
        Transform.translate(
          offset: Offset(0, -10 * transitionProgress),
          child: Opacity(
            opacity: (1 - transitionProgress).clamp(0.0, 1.0),
            child: Text(
              'UnFilter',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Collapsed Logo (Entering)
        Transform.translate(
          offset: Offset(0, 10 * (1 - transitionProgress)),
          child: Opacity(
            opacity: transitionProgress.clamp(0.0, 1.0),
            child: Row(
              children: [
                _buildLogoIcon(theme, isDark),
                const SizedBox(width: 8),
                _buildAppCountBadge(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoIcon(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(
        isDark
            ? 'assets/icons/white-unfilter-nobg.png'
            : 'assets/icons/black-unfilter-nobg.png',
        height: 20,
      ),
    );
  }

  Widget _buildAppCountBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.install_mobile,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$appCount',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
