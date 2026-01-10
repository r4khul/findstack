import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../core/widgets/app_entry.dart';
import '../../features/update/presentation/pages/update_check_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/task_manager/presentation/pages/task_manager_page.dart';
import '../../features/home/presentation/pages/info/about_page.dart';
import '../../features/home/presentation/pages/info/how_it_works_page.dart';
import '../../features/home/presentation/pages/info/privacy_page.dart';
import '../../features/apps/presentation/pages/app_details_page.dart';
import '../../features/apps/domain/entities/device_app.dart';
import '../../features/analytics/presentation/pages/storage_insights_page.dart';
import 'navigation.dart';

import '../../features/onboarding/presentation/pages/onboarding_page.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String search = '/search';
  static const String scan = '/scan';
  static const String analytics = '/analytics';
  static const String taskManager = '/task-manager';
  static const String about = '/about';
  static const String howItWorks = '/how-it-works';
  static const String privacy = '/privacy';
  static const String appDetails = '/app-details';
  static const String storageInsights = '/storage-insights';
  static const String updateCheck = '/update-check';
}

class AppRouteFactory {
  AppRouteFactory._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return PremiumPageRoute(
          page: const AppEntry(),
          settings: settings,
          transitionType: TransitionType.fade,
        );

      case AppRoutes.home:
        return BubbleRevealPageRoute(
          page: const HomePage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.search:
        return BubbleRevealPageRoute(
          page: const SearchPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.scan:
        return BubbleRevealPageRoute(
          page: const ScanPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.analytics:
        return BubbleRevealPageRoute(
          page: const AnalyticsPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.taskManager:
        return BubbleRevealPageRoute(
          page: const TaskManagerPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.about:
        return BubbleRevealPageRoute(
          page: const AboutPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.howItWorks:
        return BubbleRevealPageRoute(
          page: const HowItWorksPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.privacy:
        return BubbleRevealPageRoute(
          page: const PrivacyPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.storageInsights:
        return BubbleRevealPageRoute(
          page: const StorageInsightsPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.appDetails:
        final app = settings.arguments as DeviceApp;
        return BubbleRevealPageRoute(
          page: AppDetailsPage(app: app),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.updateCheck:
        return BubbleRevealPageRoute(
          page: const UpdateCheckPage(),
          settings: settings,
          tapPosition: TapTracker.lastTapPosition,
        );

      case AppRoutes.onboarding:
        return PremiumPageRoute(
          page: const OnboardingPage(),
          settings: settings,
          transitionType: TransitionType.fade,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }

  static Future<void> toHome(BuildContext context) {
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  static Future<void> toSearch(BuildContext context) {
    return PremiumNavigation.push(context, const SearchPage());
  }

  static Future<void> toScan(BuildContext context) {
    return PremiumNavigation.push(context, const ScanPage());
  }

  static Future<void> toAnalytics(BuildContext context) {
    return PremiumNavigation.push(context, const AnalyticsPage());
  }

  static Future<void> toTaskManager(BuildContext context) {
    return PremiumNavigation.push(context, const TaskManagerPage());
  }

  static Future<void> toAbout(BuildContext context) {
    return PremiumNavigation.push(context, const AboutPage());
  }

  static Future<void> toHowItWorks(BuildContext context) {
    return PremiumNavigation.push(context, const HowItWorksPage());
  }

  static Future<void> toPrivacy(BuildContext context) {
    return PremiumNavigation.push(context, const PrivacyPage());
  }

  static Future<void> toStorageInsights(BuildContext context) {
    return PremiumNavigation.push(context, const StorageInsightsPage());
  }

  static Future<void> toAppDetails(BuildContext context, DeviceApp app) {
    return PremiumNavigation.push(context, AppDetailsPage(app: app));
  }

  static Future<void> toUpdateCheck(BuildContext context) {
    return PremiumNavigation.push(context, const UpdateCheckPage());
  }

  static Future<void> toOnboarding(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
  }
}
