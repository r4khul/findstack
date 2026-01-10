import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/navigation.dart';
import '../../../update/presentation/providers/update_provider.dart';
import '../../../update/domain/update_service.dart';
import 'drawer/drawer_header.dart';
import 'drawer/drawer_section_header.dart';
import 'drawer/drawer_nav_tile.dart';
import 'drawer/drawer_theme_switcher.dart';
import 'drawer/drawer_open_source_card.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const double _maxWidth = 400.0;

  static const double _widthFactor = 0.85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > _maxWidth
        ? _maxWidth
        : screenWidth * _widthFactor;

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
            const AppDrawerHeader(),
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
                    const DrawerSectionHeader(title: 'APPEARANCE'),
                    const SizedBox(height: 8),
                    const DrawerThemeSwitcher(),
                    const SizedBox(height: 32),
                    _buildInsightsSection(context),
                    const SizedBox(height: 24),
                    _buildInformationSection(context, ref),
                    const SizedBox(height: 32),
                    const DrawerSectionHeader(title: 'COMMUNITY'),
                    const SizedBox(height: 12),
                    const DrawerOpenSourceCard(),
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

  Widget _buildInsightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DrawerSectionHeader(title: 'INSIGHTS'),
        const SizedBox(height: 12),
        DrawerNavTile(
          title: 'Usage Statistics',
          subtitle: 'View your digital wellbeing',
          icon: Icons.pie_chart_outline,
          onTap: () {
            Navigator.pop(context);
            AppRouteFactory.toAnalytics(context);
          },
        ),
        DrawerNavTile(
          title: 'Storage Insights',
          subtitle: 'Unfiltered space breakdown',
          icon: Icons.sd_storage_rounded,
          onTap: () {
            Navigator.pop(context);
            AppRouteFactory.toStorageInsights(context);
          },
        ),
        DrawerNavTile(
          title: 'Task Manager',
          subtitle: 'Monitor system resources',
          icon: Icons.memory_rounded,
          onTap: () {
            Navigator.pop(context);
            AppRouteFactory.toTaskManager(context);
          },
        ),
      ],
    );
  }

  Widget _buildInformationSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DrawerSectionHeader(title: 'INFORMATION'),
        const SizedBox(height: 12),
        DrawerNavTile(
          title: 'Privacy & Security',
          subtitle: 'Offline and secure',
          icon: Icons.shield_outlined,
          onTap: () {
            Navigator.pop(context);
            AppRouteFactory.toPrivacy(context);
          },
        ),
        _buildUpdateCheckTile(context, ref),
        _buildAboutTile(context, ref),
      ],
    );
  }

  Widget _buildUpdateCheckTile(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateCheckProvider);

    return DrawerNavTile(
      title: 'Check for Updates',
      subtitle: updateAsync.when(
        data: (result) {
          if (result.status == UpdateStatus.forceUpdate ||
              result.status == UpdateStatus.softUpdate) {
            return 'v${result.config?.latestNativeVersion} Available';
          }
          return "You're up to date";
        },
        loading: () => 'Checking...',
        error: (_, __) => 'Tap to retry',
      ),
      icon: Icons.system_update_rounded,
      onTap: () {
        Navigator.pop(context);
        AppRouteFactory.toUpdateCheck(context);
      },
      showBadge: updateAsync.maybeWhen(
        data: (result) =>
            result.status == UpdateStatus.forceUpdate ||
            result.status == UpdateStatus.softUpdate,
        orElse: () => false,
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(currentVersionProvider);
    final updateAsync = ref.watch(updateCheckProvider);
    final isUpdateAvailable =
        updateAsync.asData?.value.status == UpdateStatus.softUpdate;

    return DrawerNavTile(
      title: 'About',
      subtitle: versionAsync.when(
        data: (v) => 'v${v.toString()}${isUpdateAvailable ? ' • Update' : ''}',
        loading: () => 'Checking version...',
        error: (_, __) => 'Version Unknown',
      ),
      icon: Icons.info_outline,
      onTap: () {
        Navigator.pop(context);
        AppRouteFactory.toAbout(context);
      },
    );
  }
}
