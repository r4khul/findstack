library;

import 'package:flutter/material.dart';

import '../../domain/entities/active_app.dart';
import '../../domain/entities/android_process.dart';
import 'constants.dart';

class ProcessSectionHeader extends StatelessWidget {
  final String title;

  final Widget? trailing;

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

class UserSpaceSectionHeader extends StatelessWidget {
  final bool showSandboxedBadge;

  final Color indicatorColor;

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

class LiveIndicator extends StatefulWidget {
  final Color color;

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

class ShellProcessItem extends StatelessWidget {
  final AndroidProcess process;

  const ShellProcessItem({super.key, required this.process});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            _buildPidBadge(theme),
            const SizedBox(width: TaskManagerSpacing.standard),
            Expanded(child: _buildProcessInfo(theme)),
            _buildStats(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPidBadge(ThemeData theme) {
    final statusColor = _getStatusColor(theme);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(TaskManagerSizes.pidContainerPadding),
          decoration: BoxDecoration(
            color: process.isRootProcess
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
              color: process.isRootProcess
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Color _getStatusColor(ThemeData theme) {
    if (process.isRunning) return Colors.green;
    if (process.isZombie) return theme.colorScheme.error;
    if (process.isSleeping) return theme.colorScheme.outline;
    return theme.colorScheme.outline;
  }

  Widget _buildProcessInfo(ThemeData theme) {
    final displayName = process.name.length > 30
        ? "...${process.name.substring(process.name.length - 28)}"
        : process.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: TaskManagerFontSizes.body,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (process.isRunning)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'R',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
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
            _buildDivider(theme),
            Text(
              process.formattedMemory,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: TaskManagerFontSizes.sm,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (process.threads != null) ...[
              _buildDivider(theme),
              Text(
                '${process.threads} thr',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: TaskManagerFontSizes.sm,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TaskManagerSpacing.md),
      child: Container(
        width: TaskManagerSizes.dividerWidth,
        height: 10,
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${process.cpu}%",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: process.isActive
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
        if (process.nice != null && process.nice != 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'ni:${process.nice}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: TaskManagerFontSizes.tiny,
                fontFamily: 'monospace',
                color: process.nice! < 0
                    ? theme.colorScheme.error.withOpacity(0.8)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }
}

class UserAppItem extends StatelessWidget {
  final ActiveApp app;

  final AndroidProcess? matchingProcess;

  const UserAppItem({super.key, required this.app, this.matchingProcess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskManagerSpacing.lg,
        vertical: TaskManagerSpacing.sm + 2,
      ),
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
            _AppIcon(app: app, size: TaskManagerSizes.appIconSize),
            const SizedBox(width: TaskManagerSpacing.lg),
            Expanded(child: _buildAppInfo(theme)),
            _buildStats(theme),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStats(ThemeData theme) {
    if (matchingProcess != null) {
      return _buildActiveStats(theme, matchingProcess!);
    }
    return _buildCachedStats(theme);
  }

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

  Widget _buildCachedStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          app.timeAgo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: app.isRecentlyActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: app.isRecentlyActive
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        const SizedBox(height: TaskManagerSpacing.sm),
        if (app.totalTimeInForeground > 0)
          Text(
            app.formattedUsageTime,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: TaskManagerFontSizes.xs,
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }
}

class _AppIcon extends StatelessWidget {
  final ActiveApp app;
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
        child: app.icon != null && app.icon!.isNotEmpty
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
