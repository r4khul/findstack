import 'package:flutter_riverpod/flutter_riverpod.dart';

class TechStackFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setStack(String? stack) {
    state = stack;
  }
}

final techStackFilterProvider =
    NotifierProvider<TechStackFilterNotifier, String?>(
      TechStackFilterNotifier.new,
    );

class TechStacks {
  static const all = 'All';
  static const android = 'Android';
  static const flutter = 'Flutter';
  static const reactNative = 'React Native';
  static const kotlin = 'Kotlin';
  static const java = 'Java';
  static const pwa = 'PWA';
  static const ionic = 'Ionic';
  static const xamarin = 'Xamarin';
  static const jetpack = 'Jetpack';
}
