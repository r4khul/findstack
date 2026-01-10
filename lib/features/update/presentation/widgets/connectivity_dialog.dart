library;

import 'package:flutter/material.dart';

import '../../../../core/services/connectivity_service.dart';
import 'constants.dart';

void showConnectivityDialog({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required ConnectivityStatus status,
  required VoidCallback onRetry,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(UpdateOpacity.high),
    transitionDuration: UpdateAnimationDurations.standard,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Material(
            color: Colors.transparent,
            child: _ConnectivityDialogContent(
              title: title,
              message: message,
              icon: icon,
              status: status,
              onRetry: onRetry,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ),
      );
    },
  );
}

class _ConnectivityDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final ConnectivityStatus status;
  final VoidCallback onRetry;
  final ThemeData theme;
  final bool isDark;

  const _ConnectivityDialogContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.status,
    required this.onRetry,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: UpdateSpacing.xl),
      padding: const EdgeInsets.all(UpdateSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark
            ? UpdateColors.darkCardBackground
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(UpdateBorderRadius.dialog),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: UpdateBlur.shadowXL,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconContainer(),
          const SizedBox(height: UpdateSpacing.xl),
          _buildTitle(),
          const SizedBox(height: UpdateSpacing.md),
          _buildMessage(),
          const SizedBox(height: UpdateSpacing.sm),
          _buildTipsCard(),
          const SizedBox(height: UpdateSpacing.xxl),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(UpdateOpacity.light),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: theme.colorScheme.error.withOpacity(UpdateOpacity.veryHigh),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTipsCard() {
    final tips = status == ConnectivityStatus.offline
        ? [
            'Check if WiFi is enabled',
            'Check mobile data settings',
            'Try toggling airplane mode',
          ]
        : [
            'The update server may be undergoing maintenance',
            'Try again in a few minutes',
          ];

    return Container(
      margin: const EdgeInsets.only(top: UpdateSpacing.standard),
      padding: const EdgeInsets.all(UpdateSpacing.standard),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          UpdateOpacity.standard,
        ),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: UpdateSpacing.sm),
              Text(
                'Quick Tips',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: UpdateSpacing.md),
          ...tips.map((tip) => _buildTipItem(tip)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UpdateSpacing.sm - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Dismiss',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: UpdateSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
