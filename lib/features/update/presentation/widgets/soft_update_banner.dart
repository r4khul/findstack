library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_service.dart';
import 'constants.dart';
import 'update_download_button.dart';

class SoftUpdateBanner extends ConsumerStatefulWidget {
  final UpdateCheckResult result;

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
