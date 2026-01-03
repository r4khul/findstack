import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_transition_wrapper.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: UnfilterApp()));
}

class UnfilterApp extends ConsumerWidget {
  const UnfilterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'UnFilter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Disable default implicit animation to avoid conflict/overhead
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ThemeTransitionWrapper(child: child!),
      home: const SplashScreen(),
    );
  }
}
