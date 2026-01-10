import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/permission_card.dart';
import '../widgets/floating_tech_icons.dart';
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
    final notifier = ref.read(onboardingStateProvider.notifier);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PremiumPageRoute(
          page: const ScanPage(fromOnboarding: true),
          settings: const RouteSettings(name: AppRoutes.scan),
          transitionType: TransitionType.fade,
        ),
      );
    }

    await notifier.completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FloatingTechIcons(isDark: isDark, pageIndex: _currentPage),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      OnboardingPageContent(
                        title: "UnFilter",
                        description: "The Real Truth Of Apps.",
                        visual: _buildBrandingVisual(context, isDark),
                        extraContent: _buildBrandHighlights(theme),
                        isBrandTitle: true,
                      ),

                      OnboardingPageContent(
                        title: "Deep\nInsights",
                        description:
                            "Granular analysis of storage usage, install dates, and app internals.",
                        visual: _buildVisual(
                          context,
                          Icons.pie_chart_outline_rounded,
                          isDark ? Colors.white : Colors.black,
                        ),
                        extraContent: _buildFeatureList(theme),
                      ),

                      OnboardingPageContent(
                        title: "System\nAccess",
                        description:
                            "UnFilter runs entirely on-device. Your data never leaves your phone.",
                        visual: _buildVisual(
                          context,
                          Icons.shield_outlined,
                          isDark ? Colors.white : Colors.black,
                        ),
                        extraContent: SingleChildScrollView(
                          child: Column(
                            children: [
                              PermissionCard(
                                title: "Usage Activity",
                                description: "Analyze app frequency.",
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
                                title: "Package Access",
                                description: "Seamless updates & scans.",
                                icon: Icons.install_mobile_rounded,
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
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.2,
                                    ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _nextPage,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == 2 ? "Get Started" : "Continue",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () =>
                            _launchURL('https://rakhul.com/privacy'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Privacy Policy",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.onSurface
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingVisual(BuildContext context, bool isDark) {
    final assetName = isDark
        ? 'assets/icons/white-unfilter-nobg.png'
        : 'assets/icons/black-unfilter-nobg.png';

    return SizedBox(
      width: 120,
      height: 120,
      child: Image.asset(assetName, fit: BoxFit.contain),
    );
  }

  Widget _buildVisual(BuildContext context, IconData icon, Color color) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Center(child: Icon(icon, size: 64, color: color.withOpacity(0.9))),
    );
  }

  Widget _buildBrandHighlights(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildHighlightChip(theme, "Privacy First", Icons.privacy_tip_rounded),
        _buildHighlightChip(theme, "Open Source", Icons.code_rounded),
        _buildHighlightChip(theme, "No Ads", Icons.do_not_disturb_alt_rounded),
      ],
    );
  }

  Widget _buildHighlightChip(ThemeData theme, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
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
