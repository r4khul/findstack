library;

import 'package:flutter/material.dart';

import '../../data/models/update_config_model.dart';
import '../../domain/update_service.dart';
import 'constants.dart';

class UpdateCheckLoadingState extends StatelessWidget {
  final AnimationController pulseController;

  const UpdateCheckLoadingState({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                width: UpdateSizes.pulseCircleSize,
                height: UpdateSizes.pulseCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(
                    0.05 + (pulseController.value * 0.05),
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(
                      UpdateOpacity.medium,
                    ),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: UpdateSizes.progressIndicatorSize,
                    height: UpdateSizes.progressIndicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: UpdateSpacing.hero),
          Text(
            "Checking for updates...",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: UpdateSpacing.sm),
          Text(
            "This may take a moment",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateCheckErrorState extends StatelessWidget {
  final String error;

  const UpdateCheckErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetworkError = _isNetworkError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UpdateSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildErrorIcon(theme, isNetworkError),
            const SizedBox(height: UpdateSpacing.hero),
            _buildTitle(theme, isNetworkError),
            const SizedBox(height: UpdateSpacing.md),
            _buildMessage(theme, isNetworkError),
            if (isNetworkError) ...[
              const SizedBox(height: UpdateSpacing.xl),
              _buildNetworkTips(theme),
            ],
            const SizedBox(height: UpdateSpacing.bottomSafeArea),
          ],
        ),
      ),
    );
  }

  bool _isNetworkError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('internet') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket') ||
        lowerError.contains('network');
  }

  Widget _buildErrorIcon(ThemeData theme, bool isNetworkError) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(
          UpdateOpacity.medium,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        size: UpdateSizes.iconSizeLarge,
        color: theme.colorScheme.error.withOpacity(UpdateOpacity.veryHigh),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, bool isNetworkError) {
    return Text(
      isNetworkError ? "No Connection" : "Something Went Wrong",
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMessage(ThemeData theme, bool isNetworkError) {
    return Text(
      isNetworkError
          ? "Unable to check for updates. Please connect to the internet and try again."
          : "We couldn't check for updates right now. Please try again later.",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  Widget _buildNetworkTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.standard),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          UpdateOpacity.standard,
        ),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _NetworkTipRow(
            icon: Icons.wifi_rounded,
            text: 'Check WiFi connection',
          ),
          const SizedBox(height: UpdateSpacing.sm),
          _NetworkTipRow(
            icon: Icons.signal_cellular_alt_rounded,
            text: 'Check mobile data',
          ),
          const SizedBox(height: UpdateSpacing.sm),
          _NetworkTipRow(
            icon: Icons.airplanemode_active_rounded,
            text: 'Toggle airplane mode',
          ),
        ],
      ),
    );
  }
}

class _NetworkTipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NetworkTipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: UpdateSizes.iconSizeSmall,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: UpdateSpacing.md),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class UpdateCheckOfflineState extends StatelessWidget {
  final AnimationController pulseController;

  const UpdateCheckOfflineState({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UpdateSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedIcon(theme),
            const SizedBox(height: UpdateSpacing.hero),
            _buildTitle(theme),
            const SizedBox(height: UpdateSpacing.md),
            _buildMessage(theme),
            const SizedBox(height: UpdateSpacing.hero),
            _buildNetworkOptionsCard(theme),
            const SizedBox(height: UpdateSpacing.section),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(UpdateSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(
              0.08 + (pulseController.value * 0.04),
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.orange.withOpacity(UpdateOpacity.medium),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            size: UpdateSizes.iconSizeLarge,
            color: Colors.orange.withOpacity(UpdateOpacity.nearlyOpaque),
          ),
        );
      },
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      "You're Offline",
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMessage(ThemeData theme) {
    return Text(
      "Connect to the internet to check for updates and download new versions.",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  Widget _buildNetworkOptionsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          UpdateOpacity.standard,
        ),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
        ),
      ),
      child: Column(
        children: [
          _NetworkOptionItem(
            icon: Icons.wifi_rounded,
            title: "WiFi",
            subtitle: "Connect to a wireless network",
          ),
          Divider(
            height: UpdateSpacing.xl,
            color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
          ),
          _NetworkOptionItem(
            icon: Icons.signal_cellular_alt_rounded,
            title: "Mobile Data",
            subtitle: "Enable cellular data in settings",
          ),
        ],
      ),
    );
  }
}

class _NetworkOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NetworkOptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(UpdateOpacity.light),
            borderRadius: BorderRadius.circular(UpdateBorderRadius.md),
          ),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: UpdateSpacing.standard),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UpdateCheckResultState extends StatelessWidget {
  final UpdateCheckResult result;

  const UpdateCheckResultState({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpdateAvailable =
        result.status == UpdateStatus.softUpdate ||
        result.status == UpdateStatus.forceUpdate;
    final currentVersion = result.currentVersion?.toString() ?? "Unknown";

    return Column(
      children: [
        if (!isUpdateAvailable) const Spacer(),
        _buildHeroIcon(theme, isUpdateAvailable),
        const SizedBox(height: UpdateSpacing.hero),
        _buildStatusText(theme, isUpdateAvailable, currentVersion),
        const SizedBox(height: UpdateSpacing.section),
        if (isUpdateAvailable && result.config != null)
          _VersionComparisonCard(
            currentVersion: currentVersion,
            newVersion: result.config!.latestNativeVersion.toString(),
          ),
        if (isUpdateAvailable &&
            result.config != null &&
            (result.config!.hasChangelog ||
                result.config!.releaseNotes != null)) ...[
          const SizedBox(height: UpdateSpacing.xl),
          _ChangelogCard(config: result.config!),
        ],
        if (!isUpdateAvailable) const Spacer(),
        const SizedBox(height: UpdateSpacing.bottomNavClearance),
      ],
    );
  }

  Widget _buildHeroIcon(ThemeData theme, bool isUpdateAvailable) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: UpdateAnimationDurations.slow,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(UpdateSpacing.hero),
            decoration: BoxDecoration(
              color: isUpdateAvailable
                  ? theme.colorScheme.primary.withOpacity(UpdateOpacity.light)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(
                      UpdateOpacity.high,
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUpdateAvailable
                    ? theme.colorScheme.primary.withOpacity(
                        UpdateOpacity.medium,
                      )
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isUpdateAvailable
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(
                          UpdateOpacity.medium,
                        ),
                        blurRadius: UpdateBlur.shadowLarge,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isUpdateAvailable
                  ? Icons.rocket_launch_rounded
                  : Icons.check_circle_rounded,
              size: UpdateSizes.heroIconSize,
              color: isUpdateAvailable
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(
    ThemeData theme,
    bool isUpdateAvailable,
    String currentVersion,
  ) {
    return Column(
      children: [
        Text(
          isUpdateAvailable ? "Update Available" : "You're up to date",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: UpdateSpacing.md),
        Text(
          isUpdateAvailable
              ? "A new version of Unfilter is ready."
              : "Unfilter v$currentVersion is the latest version.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VersionComparisonCard extends StatelessWidget {
  final String currentVersion;
  final String newVersion;

  const _VersionComparisonCard({
    required this.currentVersion,
    required this.newVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: UpdateSpacing.xl,
        horizontal: UpdateSpacing.standard,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(UpdateOpacity.verySubtle),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionColumn(
              label: "Current",
              version: "v$currentVersion",
              isNew: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(UpdateSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                UpdateOpacity.high,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: UpdateSizes.versionArrowSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _VersionColumn(
              label: "Newest",
              version: "v$newVersion",
              isNew: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionColumn extends StatelessWidget {
  final String label;
  final String version;
  final bool isNew;

  const _VersionColumn({
    required this.label,
    required this.version,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isNew
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: UpdateSpacing.sm),
        isNew
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UpdateSpacing.md,
                  vertical: UpdateSpacing.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(
                    UpdateOpacity.light,
                  ),
                  borderRadius: BorderRadius.circular(UpdateBorderRadius.md),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(
                      UpdateOpacity.medium,
                    ),
                  ),
                ),
                child: Text(
                  version,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                    letterSpacing: -0.5,
                  ),
                ),
              )
            : Text(
                version,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                ),
              ),
      ],
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final UpdateConfigModel config;

  const _ChangelogCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UpdateSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(UpdateOpacity.verySubtle),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: UpdateSpacing.xl),
          if (config.releaseNotes != null) ...[
            Text(
              config.releaseNotes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: UpdateSpacing.xl),
          ],
          if (config.features.isNotEmpty) ...[
            _ChangelogSection(
              title: "FEATURES",
              items: config.features,
              icon: Icons.star_rounded,
              color: UpdateColors.featureGreen,
            ),
            const SizedBox(height: UpdateSpacing.xl),
          ],
          if (config.fixes.isNotEmpty)
            _ChangelogSection(
              title: "FIXES",
              items: config.fixes,
              icon: Icons.bug_report_rounded,
              color: UpdateColors.fixBlue,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(UpdateOpacity.light),
            borderRadius: BorderRadius.circular(UpdateBorderRadius.md),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: UpdateSizes.iconSize,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: UpdateSpacing.standard),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's New",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "See what has changed",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChangelogSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _ChangelogSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 11,
            color: color,
          ),
        ),
        const SizedBox(height: UpdateSpacing.md),
        ...items.map(
          (item) => _ChangelogItem(text: item, icon: icon, color: color),
        ),
      ],
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _ChangelogItem({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: UpdateSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(UpdateOpacity.light),
              borderRadius: BorderRadius.circular(UpdateBorderRadius.sm),
            ),
            child: Icon(
              icon,
              size: UpdateSizes.changelogIconContainerSize,
              color: color,
            ),
          ),
          const SizedBox(width: UpdateSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
