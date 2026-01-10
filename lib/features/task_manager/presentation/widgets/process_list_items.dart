/// List item widgets for displaying processes in the task manager.
///
/// Contains widgets for:
/// - Shell/system processes (kernel level)
/// - User app processes (active apps)
/// - Section headers with live indicators
library;

import 'package:flutter/material.dart';

import '../../../../core/navigation/navigation.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../domain/entities/android_process.dart';
import 'constants.dart';

// =============================================================================
// SECTION HEADERS
// =============================================================================

/// A section header for process lists with optional live indicator.
///
/// Displays a label and optionally a live indicator or badge.
class ProcessSectionHeader extends StatelessWidget {
  /// The section title text.
  final String title;

  /// Optional widget to display on the right side.
  final Widget? trailing;

  /// Creates a process section header.
  const ProcessSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TaskManagerSpacing.sectionHorizontal,
        TaskManagerSpacing.sectionTop,
        TaskManagerSpacing.sectionHorizontal,
        TaskManagerSpacing.sectionBottom,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: theme.colorScheme.onSurface.withOpacity(
                TaskManagerOpacity.headerLabel,
              ),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// User space section header with conditional badge.
class UserSpaceSectionHeader extends StatelessWidget {
  /// Whether the sandboxed badge should be shown instead of live indicator.
  final bool showSandboxedBadge;

  /// The color for the live indicator.
  final Color indicatorColor;

  /// Creates a user space section header.
  const UserSpaceSectionHeader({
    super.key,
    required this.showSandboxedBadge,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TaskManagerSpacing.sectionHorizontal,
        TaskManagerSpacing.userSectionTop,
        TaskManagerSpacing.sectionHorizontal,
        TaskManagerSpacing.sectionBottom,
      ),
      child: Row(
        children: [
          Text(
            "USER SPACE (ACTIVE)",
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: theme.colorScheme.onSurface.withOpacity(
                TaskManagerOpacity.headerLabel,
              ),
            ),
          ),
          const Spacer(),
          if (showSandboxedBadge)
            Text(
              "SANDBOXED",
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: TaskManagerFontSizes.xs,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(
                  TaskManagerOpacity.half,
                ),
              ),
            )
          else
            LiveIndicator(color: indicatorColor),
        ],
      ),
    );
  }
}

// =============================================================================
// LIVE INDICATOR
// =============================================================================

/// An animated live indicator with pulsing effect.
///
/// Shows a "LIVE" badge with dot indicator that fades in and out.
class LiveIndicator extends StatefulWidget {
  /// The color of the indicator.
  final Color color;

  /// Creates a live indicator.
  const LiveIndicator({super.key, required this.color});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TaskManagerDurations.livePulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TaskManagerSpacing.md,
          vertical: TaskManagerSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(TaskManagerOpacity.light),
          borderRadius: BorderRadius.circular(TaskManagerBorderRadius.badge),
          border: Border.all(
            color: widget.color.withOpacity(TaskManagerOpacity.half),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: TaskManagerSizes.liveIndicatorDotSize,
              height: TaskManagerSizes.liveIndicatorDotSize,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: TaskManagerSpacing.sm),
            Text(
              "LIVE",
              style: TextStyle(
                fontSize: TaskManagerFontSizes.sm,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHELL PROCESS ITEM
// =============================================================================

/// A list item for displaying shell/kernel processes.
///
/// Shows process ID, name, user, RSS memory, and CPU usage.
class ShellProcessItem extends StatelessWidget {
  /// The Android process to display.
  final AndroidProcess process;

  /// Creates a shell process item.
  const ShellProcessItem({super.key, required this.process});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isRoot = process.user == 'root';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskManagerSpacing.lg,
        vertical: TaskManagerSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(TaskManagerSpacing.standard),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(TaskManagerBorderRadius.standard),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(
              TaskManagerOpacity.light,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildPidBadge(theme, isRoot),
            const SizedBox(width: TaskManagerSpacing.standard),
            Expanded(child: _buildProcessInfo(theme)),
            _buildCpuUsage(theme),
          ],
        ),
      ),
    );
  }

  /// Builds the PID badge container.
  Widget _buildPidBadge(ThemeData theme, bool isRoot) {
    return Container(
      padding: const EdgeInsets.all(TaskManagerSizes.pidContainerPadding),
      decoration: BoxDecoration(
        color: isRoot
            ? theme.colorScheme.error.withOpacity(TaskManagerOpacity.light)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(
                TaskManagerOpacity.standard,
              ),
        borderRadius: BorderRadius.circular(TaskManagerBorderRadius.md),
      ),
      child: Text(
        process.pid,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: isRoot ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// Builds the process name and user info.
  Widget _buildProcessInfo(ThemeData theme) {
    final displayName = process.name.length > 30
        ? "...${process.name.substring(process.name.length - 28)}"
        : process.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: TaskManagerFontSizes.body,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: TaskManagerSpacing.xs),
        Row(
          children: [
            Text(
              process.user,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: TaskManagerFontSizes.sm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: TaskManagerSpacing.md),
            Container(
              width: TaskManagerSizes.dividerWidth,
              height: 10,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: TaskManagerSpacing.md),
            Text(
              "RSS: ${process.res}",
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: TaskManagerFontSizes.sm,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the CPU usage display.
  Widget _buildCpuUsage(ThemeData theme) {
    final isActive = process.cpu != "0.0" && process.cpu != "0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${process.cpu}%",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          "CPU",
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: TaskManagerFontSizes.tiny,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(
              TaskManagerOpacity.half,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// USER APP ITEM
// =============================================================================

/// A list item for displaying active user applications.
///
/// Shows app icon, name, package name, and either CPU/RSS stats
/// or last used time with cached badge.
class UserAppItem extends StatelessWidget {
  /// The device app to display.
  final DeviceApp app;

  /// Optional matching shell process for CPU/memory stats.
  final AndroidProcess? matchingProcess;

  /// Creates a user app item.
  const UserAppItem({super.key, required this.app, this.matchingProcess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskManagerSpacing.lg,
        vertical: TaskManagerSpacing.sm + 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AppRouteFactory.toAppDetails(context, app),
          borderRadius: BorderRadius.circular(TaskManagerBorderRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(TaskManagerSpacing.standard),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(TaskManagerBorderRadius.lg),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(
                  TaskManagerOpacity.mediumLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'task_manager_${app.packageName}',
                  child: _AppIcon(app: app, size: TaskManagerSizes.appIconSize),
                ),
                const SizedBox(width: TaskManagerSpacing.lg),
                Expanded(child: _buildAppInfo(theme)),
                _buildStats(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app name and package info.
  Widget _buildAppInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.appName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          app.packageName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: TaskManagerFontSizes.sm,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds the stats section (CPU/RSS or time ago).
  Widget _buildStats(ThemeData theme) {
    if (matchingProcess != null) {
      return _buildActiveStats(theme, matchingProcess!);
    }
    return _buildCachedStats(theme);
  }

  /// Builds stats for apps with active processes.
  Widget _buildActiveStats(ThemeData theme, AndroidProcess process) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${process.cpu}% CPU",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          "RSS: ${process.res}",
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: TaskManagerFontSizes.xs,
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Builds stats for cached (inactive) apps.
  Widget _buildCachedStats(ThemeData theme) {
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);

    String timeAgo;
    if (diff.inSeconds < 60) {
      timeAgo = "Active now";
    } else if (diff.inMinutes < 60) {
      timeAgo = "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      timeAgo = "${diff.inHours}h ago";
    } else {
      timeAgo = "${diff.inDays}d ago";
    }

    final isRecent = diff.inMinutes < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeAgo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isRecent
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isRecent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: TaskManagerSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TaskManagerSpacing.sm + 2,
            vertical: TaskManagerSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(TaskManagerBorderRadius.sm),
          ),
          child: Text(
            "CACHED",
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: TaskManagerFontSizes.xs,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// APP ICON
// =============================================================================

/// A circular app icon widget.
class _AppIcon extends StatelessWidget {
  final DeviceApp app;
  final double size;

  const _AppIcon({required this.app, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: app.icon != null
            ? Image.memory(
                app.icon!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Icon(Icons.android),
              )
            : const Icon(Icons.android),
      ),
    );
  }
}
