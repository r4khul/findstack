import 'package:flutter_riverpod/legacy.dart';

final techStackFilterProvider = StateProvider<String?>((ref) => null);

// Constants for tech stacks matching SVG names or logic
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
