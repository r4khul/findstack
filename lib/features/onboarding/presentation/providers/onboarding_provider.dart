import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs);
});

final onboardingStateProvider = NotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repository = ref.watch(onboardingRepositoryProvider);
    return repository.hasCompletedOnboarding();
  }

  Future<void> completeOnboarding() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.completeOnboarding();
    state = true;
  }
}
