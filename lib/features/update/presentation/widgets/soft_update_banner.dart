/// A banner widget displayed when a soft (optional) update is available.
///
/// This banner appears at the bottom of the screen with a slide-in animation
/// and can be dismissed by the user. It provides a quick way to download
/// the update without blocking app usage.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_service.dart';
import 'constants.dart';
import 'update_download_button.dart';

/// A dismissible banner shown when an optional update is available.
///
/// The banner:
/// - Slides in from the bottom with an elastic animation
/// - Shows version information
/// - Contains a download button
/// - Can be dismissed without updating
/// - Uses glassmorphism for a premium look
///
/// ## Animation Behavior
/// - Appears 2 seconds after mounting to avoid interfering with initial load
/// - Uses [Curves.elasticOut] for a bouncy entrance
/// - Slides out when dismissed
///
/// ## Usage
/// This is typically shown by [VersionCheckGate] when the update check
/// returns [UpdateStatus.softUpdate].
class SoftUpdateBanner extends ConsumerStatefulWidget {
  /// The result of the update check containing version information.
  final UpdateCheckResult result;

  /// Creates a soft update banner.
  ///
  /// [result] contains the update check result with version details.
  const SoftUpdateBanner({super.key, required this.result});

  @override
  ConsumerState<SoftUpdateBanner> createState() => _SoftUpdateBannerState();
}

class _SoftUpdateBannerState extends ConsumerState<SoftUpdateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scheduleEntrance();
  }

  /// Initializes the slide animation controller and offset animation.
  void _initializeAnimations() {
    _controller = AnimationController(
      duration: UpdateAnimationDurations.slideIn,
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  /// Schedules the banner entrance with a delay.
  void _scheduleEntrance() {
    Future.delayed(UpdateAnimationDurations.bannerDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Dismisses the banner with a slide-out animation.
  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          UpdateSpacing.standard,
          0,
          UpdateSpacing.standard,
          UpdateSpacing.hero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
          child: BackdropFilter(
            filter: standardBlurFilter,
            child: Container(
              padding: const EdgeInsets.all(UpdateSpacing.lg),
              decoration: _buildDecoration(theme),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: UpdateSpacing.lg),
                  UpdateDownloadButton(
                    url: widget.result.config?.apkDirectDownloadUrl,
                    version:
                        widget.result.config?.latestNativeVersion.toString() ??
                        'latest',
                    isCompact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the glassmorphism decoration for the banner.
  BoxDecoration _buildDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor.withOpacity(UpdateOpacity.nearlyOpaque),
      borderRadius: BorderRadius.circular(UpdateBorderRadius.xl),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(UpdateOpacity.light),
          blurRadius: UpdateBlur.shadowLarge,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Builds the header row with icon, version info, and dismiss button.
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        _buildIconContainer(theme),
        const SizedBox(width: UpdateSpacing.standard),
        Expanded(child: _buildVersionInfo(theme)),
        _buildDismissButton(theme),
      ],
    );
  }

  /// Builds the update icon container.
  Widget _buildIconContainer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(UpdateOpacity.light),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.md),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: theme.colorScheme.primary,
        size: UpdateSizes.iconSize,
      ),
    );
  }

  /// Builds the version information column.
  Widget _buildVersionInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update Available',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'v${widget.result.config?.latestNativeVersion} is ready',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Builds the dismiss button.
  Widget _buildDismissButton(ThemeData theme) {
    return IconButton(
      onPressed: _dismiss,
      icon: Icon(
        Icons.close,
        color: theme.colorScheme.onSurfaceVariant,
        size: UpdateSizes.iconSize,
      ),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(UpdateSpacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
