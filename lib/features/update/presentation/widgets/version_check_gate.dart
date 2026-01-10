/// A gate widget that checks for app updates and shows appropriate UI.
///
/// This widget wraps the main app content and:
/// - Shows a [ForceUpdateScreen] if a critical update is required
/// - Shows a [SoftUpdateBanner] overlay if an optional update is available
/// - Passes through the child widget when no update is needed or still loading
///
/// The gate respects the onboarding flow and won't show update prompts until
/// onboarding is complete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_service.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/update_provider.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/navigation/active_route_provider.dart';
import 'force_update_screen.dart';
import 'soft_update_banner.dart';

/// A consumer widget that gates app access based on update status.
///
/// This widget should wrap the main app content at a high level in the
/// widget tree. It monitors the [updateCheckProvider] and decides whether
/// to show the normal app, a force update screen, or overlay a soft update
/// banner.
///
/// ## Usage
/// ```dart
/// VersionCheckGate(
///   child: MyApp(),
/// )
/// ```
///
/// ## Behavior
/// - During loading: Shows child passively
/// - On error: Logs error and shows child (doesn't block app)
/// - Force update: Replaces child with [ForceUpdateScreen]
/// - Soft update: Overlays [SoftUpdateBanner] on child
/// - Up to date: Shows child normally
class VersionCheckGate extends ConsumerWidget {
  /// The main app content to display when no blocking update is required.
  final Widget child;

  /// Creates a version check gate.
  ///
  /// [child] is the main app content that will be shown when permitted.
  const VersionCheckGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check onboarding status first - suppress updates until complete
    final hasCompletedOnboarding = ref.watch(onboardingStateProvider);
    if (!hasCompletedOnboarding) {
      return Stack(children: [child]);
    }

    // Watch the update check result
    final updateResultAsync = ref.watch(updateCheckProvider);
    final activeRoute = ref.watch(activeRouteProvider);

    return updateResultAsync.when(
      data: (result) {
        // Force update blocks the entire app
        if (result.status == UpdateStatus.forceUpdate) {
          return ForceUpdateScreen(result: result);
        }

        // Check if we should suppress the banner on specific pages
        final shouldShowBanner =
            result.status == UpdateStatus.softUpdate &&
            activeRoute != AppRoutes.scan;

        // Ensure child is built even if soft update is available
        // We will overlay the banner using a Stack
        return Stack(
          children: [
            child,
            if (shouldShowBanner)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SoftUpdateBanner(result: result),
              ),
          ],
        );
      },
      loading: () =>
          Stack(children: [child]), // Passively show app while loading
      error: (e, stack) {
        // Log error but don't block app
        debugPrint('Update check error: $e');
        return Stack(children: [child]);
      },
    );
  }
}
