import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tile widget for displaying external link items.
///
/// Shows a label, value, and arrow icon that launches the provided URL
/// in an external browser when tapped. Used in info pages for social
/// links and external references.
class ExternalLinkTile extends StatelessWidget {
  /// Descriptive label for the link.
  final String label;

  /// Display value (e.g., username, "View", etc.).
  final String value;

  /// URL to launch when tapped.
  final String url;

  /// Creates an external link tile.
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
        color: theme.colorScheme.onSurface.withOpacity(0.6),
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
        const SizedBox(width: 4),
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
