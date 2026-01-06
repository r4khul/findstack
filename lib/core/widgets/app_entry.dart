import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

/// Entry point widget that decides which screen to show based on application state.
/// It also handles the removal of the native splash screen.
class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingStateProvider);

    return onboardingState.when(
      data: (hasCompletedOnboarding) {
        // Post-frame callback to ensure the widget is built before removing splash
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });

        if (hasCompletedOnboarding) {
          return const HomePage();
        } else {
          return const OnboardingPage();
        }
      },
      error: (error, stack) {
        // Fallback in case of error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
        return const OnboardingPage();
      },
      loading: () {
        // Keep showing the native splash screen (by not removing it)
        // detailed logic is handled by FlutterNativeSplash.preserve() in main.dart
        return const SizedBox.shrink();
      },
    );
  }
}
