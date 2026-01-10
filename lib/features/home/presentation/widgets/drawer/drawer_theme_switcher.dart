import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/widgets/theme_transition_wrapper.dart';

/// Theme switcher widget with animated sliding indicator.
///
/// Displays three theme options (Light, Auto, Dark) with a smooth
/// sliding indicator animation. Integrates with the app's theme provider
/// and supports the circular reveal transition effect.
class DrawerThemeSwitcher extends ConsumerWidget {
  /// Creates a drawer theme switcher.
  const DrawerThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);

    // Calculate alignment for the sliding indicator
    // -1.0 (Left/Light), 0.0 (Center/Auto), 1.0 (Right/Dark)
    final alignmentX = switch (currentTheme) {
      ThemeMode.light => -1.0,
      ThemeMode.dark => 1.0,
      ThemeMode.system => 0.0,
    };

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // Animated sliding indicator
          AnimatedAlign(
            alignment: Alignment(alignmentX, 0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            child: FractionallySizedBox(
              widthFactor: 0.333,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Theme option buttons
          Row(
            children: [
              _ThemeOption(
                mode: ThemeMode.light,
                icon: Icons.wb_sunny_rounded,
                label: 'Light',
                isSelected: currentTheme == ThemeMode.light,
              ),
              _ThemeOption(
                mode: ThemeMode.system,
                icon: Icons.hdr_auto_rounded,
                label: 'Auto',
                isSelected: currentTheme == ThemeMode.system,
              ),
              _ThemeOption(
                mode: ThemeMode.dark,
                icon: Icons.nightlight_round,
                label: 'Dark',
                isSelected: currentTheme == ThemeMode.dark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual theme option button within the switcher.
class _ThemeOption extends ConsumerWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (mode == ref.read(themeProvider)) return;

          HapticFeedback.mediumImpact();

          ThemeTransitionWrapper.of(context).switchTheme(
            center: details.globalPosition,
            onThemeSwitch: () {
              ref.read(themeProvider.notifier).setTheme(mode);
            },
          );
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: color,
          ),
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 200),
              tween: ColorTween(end: color),
              builder: (context, animatedColor, child) {
                return Icon(icon, size: 20, color: animatedColor);
              },
            ),
          ),
        ),
      ),
    );
  }
}
