import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../update/domain/update_service.dart';
import '../../../update/presentation/providers/update_provider.dart';

/// Settings menu button for the home page app bar.
///
/// Opens the app drawer when tapped. Displays a notification badge
/// when an app update is available.
class SettingsMenu extends ConsumerWidget {
  /// Creates a settings menu button.
  const SettingsMenu({super.key});

  /// Badge size for update indicator.
  static const double _badgeSize = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updateAsync = ref.watch(updateCheckProvider);

    final hasUpdate = updateAsync.maybeWhen(
      data: (result) =>
          result.status == UpdateStatus.softUpdate ||
          result.status == UpdateStatus.forceUpdate,
      orElse: () => false,
    );

    return IconButton(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.only(left: 8),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildMenuIcon(theme),
          if (hasUpdate) _buildUpdateBadge(theme),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.menu_rounded,
        size: 22,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildUpdateBadge(ThemeData theme) {
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        width: _badgeSize,
        height: _badgeSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
