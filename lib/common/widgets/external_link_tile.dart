library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';

/// A tile that displays a label/value pair and opens an external URL on tap.
class ExternalLinkTile extends StatelessWidget {
  final String label;
  final String value;
  final String url;

  const ExternalLinkTile({
    super.key,
    required this.label,
    required this.value,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildLabel(theme), _buildValue(theme)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(AppOpacity.high),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildValue(ThemeData theme) {
    return Row(
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(
          Icons.arrow_outward_rounded,
          size: 14,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
      ],
    );
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
