import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/theme_transition_wrapper.dart';
import '../../../../core/navigation/navigation.dart';
import '../providers/github_stars_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    // slightly wider for better readability of "micro details"
    final drawerWidth = width > 400 ? 400.0 : width * 0.85;

    return Drawer(
      width: drawerWidth,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, "APPEARANCE"),
                    const SizedBox(height: 8),
                    _buildThemeSwitcher(context, ref),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "INSIGHTS"),
                    const SizedBox(height: 12),
                    _buildNavTile(
                      context,
                      title: "Usage Statistics",
                      subtitle: "View your digital wellbeing",
                      icon: Icons.pie_chart_outline,
                      onTap: () {
                        Navigator.pop(context);
                        AppRouteFactory.toAnalytics(context);
                      },
                    ),
                    _buildNavTile(
                      context,
                      title: "Task Manager",
                      subtitle: "Monitor system resources",
                      icon: Icons.memory_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        AppRouteFactory.toTaskManager(context);
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(context, "INFORMATION"),
                    const SizedBox(height: 12),
                    _buildNavTile(
                      context,
                      title: "How it works",
                      subtitle: "Tech detection explained",
                      icon: Icons.lightbulb_outline,
                      onTap: () {
                        Navigator.pop(context);
                        AppRouteFactory.toHowItWorks(context);
                      },
                    ),
                    _buildNavTile(
                      context,
                      title: "Privacy & Security",
                      subtitle: "Offline and secure",
                      icon: Icons.shield_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        AppRouteFactory.toPrivacy(context);
                      },
                    ),
                    _buildNavTile(
                      context,
                      title: "About",
                      subtitle: "Version 1.0.0",
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.pop(context);
                        AppRouteFactory.toAbout(context);
                      },
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "COMMUNITY"),
                    const SizedBox(height: 12),
                    _buildOpenSourceCard(context, ref),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Menu",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Settings & Info",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.3),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  // --- Theme Switcher ---

  // --- Theme Switcher ---

  Widget _buildThemeSwitcher(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);

    // Calculate alignment for the sliding indicator
    // -1.0 (Left/Light), 0.0 (Center/Auto), 1.0 (Right/Dark)
    double alignmentX = 0.0;
    if (currentTheme == ThemeMode.light) alignmentX = -1.0;
    if (currentTheme == ThemeMode.dark) alignmentX = 1.0;

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
          // The sliding high-performance indicator
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
          // The clickable icons
          Row(
            children: [
              _buildStaticThemeOption(
                context,
                ref,
                ThemeMode.light,
                Icons.wb_sunny_rounded,
                "Light",
                currentTheme == ThemeMode.light,
              ),
              _buildStaticThemeOption(
                context,
                ref,
                ThemeMode.system,
                Icons.hdr_auto_rounded,
                "Auto",
                currentTheme == ThemeMode.system,
              ),
              _buildStaticThemeOption(
                context,
                ref,
                ThemeMode.dark,
                Icons.nightlight_round,
                "Dark",
                currentTheme == ThemeMode.dark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    // Color transition only - cheap paint operation
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (mode == ref.read(themeProvider)) return;

          // Pro-level haptic feedback
          HapticFeedback.mediumImpact();

          // Trigger the high-performance circular reveal transition
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
              builder: (context, color, child) {
                return Icon(icon, size: 20, color: color);
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Detailed Navigation Tile ---

  Widget _buildNavTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          overlayColor: WidgetStateProperty.all(
            theme.colorScheme.primary.withOpacity(0.05),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Open Source Card ---

  Widget _buildOpenSourceCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final starsAsync = ref.watch(githubStarsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final url = Uri.parse("https://github.com/r4khul/unfilter");
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/vectors/icon_github.svg',
                    height: 20,
                    width: 20,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Open Source",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Star us on GitHub",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      starsAsync.when(
                        data: (stars) => Text(
                          "$stars",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        error: (_, __) => const Text("-"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
