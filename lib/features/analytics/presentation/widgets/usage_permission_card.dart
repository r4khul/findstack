import 'package:flutter/material.dart';

import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsagePermissionCard extends ConsumerWidget {
  final bool hasPermission;

  const UsagePermissionCard({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(theme),
              const SizedBox(height: 32),
              _buildTitle(theme),
              const SizedBox(height: 12),
              _buildDescription(theme),
              const SizedBox(height: 36),
              _buildActionButton(context, ref, theme),
              if (hasPermission) _buildHint(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final color = hasPermission
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasPermission
                ? Icons.query_stats_rounded
                : Icons.shield_moon_rounded,
            size: 36,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      hasPermission ? 'No Insights Yet' : 'Unlock Insights',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      hasPermission
          ? 'Deep scan required to analyze your usage patterns tailored to your lifestyle.'
          : 'Grant usage access to see exactly where your time goes. Your data stays 100% private on this device.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: () async {
          if (hasPermission) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanPage()));
          } else {
            final repo = ref.read(deviceAppsRepositoryProvider);
            await repo.requestUsagePermission();
            ref.invalidate(usagePermissionProvider);
          }
        },
        style:
            FilledButton.styleFrom(
              backgroundColor: hasPermission
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                return Colors.white.withOpacity(0.1);
              }),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPermission
                  ? Icons.bolt_rounded
                  : Icons.settings_accessibility_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              hasPermission ? 'Start Deep Analysis' : 'Enable Access',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        'Takes about 20 seconds',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
