import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider((ref) => OnboardingRepository());

final onboardingStateProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  () {
    return OnboardingNotifier();
  },
);

class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.watch(onboardingRepositoryProvider);
    return await repository.hasCompletedOnboarding();
  }

  Future<void> completeOnboarding() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.completeOnboarding();
    state = const AsyncValue.data(true);
  }
}
