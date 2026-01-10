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

class VersionCheckGate extends ConsumerWidget {
  final Widget child;

  const VersionCheckGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(onboardingStateProvider);
    if (!hasCompletedOnboarding) {
      return Stack(children: [child]);
    }

    final updateResultAsync = ref.watch(updateCheckProvider);
    final activeRoute = ref.watch(activeRouteProvider);

    return updateResultAsync.when(
      data: (result) {
        if (result.status == UpdateStatus.forceUpdate) {
          return ForceUpdateScreen(result: result);
        }

        final shouldShowBanner =
            result.status == UpdateStatus.softUpdate &&
            activeRoute != AppRoutes.scan;

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
          Stack(children: [child]),
      error: (e, stack) {
        debugPrint('Update check error: $e');
        return Stack(children: [child]);
      },
    );
  }
}
