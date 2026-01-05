import 'package:flutter/material.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_transition_wrapper.dart';
import 'core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'core/version/update_ui.dart';

void main() {
  runApp(const ProviderScope(child: UnfilterApp()));
}

class UnfilterApp extends ConsumerWidget {
  const UnfilterApp({super.key});

  static final GlobalKey appKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      key: appKey,
      title: 'UnFilter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => RepaintBoundary(
        key: PremiumNavigation.rootBoundaryKey,
        child: VersionGate(
          child: TapPositionProvider(
            child: ThemeTransitionWrapper(child: child!),
          ),
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: AppRouteFactory.onGenerateRoute,
      navigatorObservers: [AppNavigatorObserver()],
    );
  }
}
