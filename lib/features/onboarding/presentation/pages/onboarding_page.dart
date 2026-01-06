import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/permission_card.dart';
import '../../../scan/presentation/pages/scan_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isUsageGranted = false;
  bool _isInstallGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final repo = ref.read(deviceAppsRepositoryProvider);
    final usage = await repo.checkUsagePermission();
    final install = await repo.checkInstallPermission();

    if (mounted) {
      setState(() {
        _isUsageGranted = usage;
        _isInstallGranted = install;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PremiumPageRoute(
          page: const ScanPage(fromOnboarding: true),
          settings: const RouteSettings(name: AppRoutes.scan),
          transitionType: TransitionType.fade,
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      // Enforce Permissions on Last Page
      if (!_isUsageGranted || !_isInstallGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please grant all permissions to continue using UnFilter.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Page 1: Intro
                  OnboardingPageContent(
                    title: "Peek Under\nthe Hood",
                    description:
                        "Discover the technologies and libraries widely used by the apps on your device.",
                    visual: _buildVisual(
                      context,
                      Icons.layers_rounded,
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  // Page 2: Features
                  OnboardingPageContent(
                    title: "Granular\nInsights",
                    description:
                        "Get detailed breakdowns of storage usage, install dates, and tech stacks.",
                    visual: _buildVisual(
                      context,
                      Icons.pie_chart_rounded,
                      isDark ? Colors.white : Colors.black,
                    ),
                    extraContent: _buildFeatureList(theme),
                  ),

                  // Page 3: Permissions
                  OnboardingPageContent(
                    title: "Trust &\nTransparency",
                    description:
                        "UnFilter runs entirely on-device. We need these permissions to analyze your apps.",
                    visual: _buildVisual(
                      context,
                      Icons.shield_moon_rounded,
                      isDark ? Colors.white : Colors.black,
                    ),
                    extraContent: Column(
                      children: [
                        PermissionCard(
                          title: "Usage Stats",
                          description: "To analyze app usage frequency.",
                          icon: Icons.bar_chart_rounded,
                          isGranted: _isUsageGranted,
                          onTap: () async {
                            await ref
                                .read(deviceAppsRepositoryProvider)
                                .requestUsagePermission();
                          },
                        ),
                        const SizedBox(height: 12),
                        PermissionCard(
                          title: "Install Apps",
                          description:
                              "To enable seamless updates.", // Simplified description
                          icon: Icons.system_update_rounded,
                          isGranted: _isInstallGranted,
                          onTap: () async {
                            await ref
                                .read(deviceAppsRepositoryProvider)
                                .requestInstallPermission();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer / Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ensure it takes minimum space
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24), // Reduced from 32
                  // Main CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52, // Slightly reduced from 56
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 2
                            ? (_isUsageGranted && _isInstallGranted
                                  ? "Get Started"
                                  : "Grant Permissions First")
                            : "Continue",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // Reduced from 24
                  // Privacy Policy
                  TextButton(
                    onPressed: () {
                      _launchURL('https://rakhul.com/privacy');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Privacy Policy",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(BuildContext context, IconData icon, Color color) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Center(child: Icon(icon, size: 48, color: color)),
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    return Column(
      children: [
        _buildFeatureItem(theme, Icons.analytics_outlined, "Storage Analysis"),
        _buildFeatureItem(theme, Icons.memory, "Tech Stack Detection"),
        _buildFeatureItem(
          theme,
          Icons.monitor_heart_outlined,
          "System Monitoring",
        ),
      ],
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
