import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_transition_wrapper.dart';
import 'core/widgets/app_entry.dart';
import 'core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/update/presentation/widgets/update_ui.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
        child: VersionCheckGate(
          child: TapPositionProvider(
            child: ThemeTransitionWrapper(child: child!),
          ),
        ),
      ),
      home: const AppEntry(),
      onGenerateRoute: AppRouteFactory.onGenerateRoute,
      navigatorObservers: [AppNavigatorObserver(ref: ref)],
    );
  }
}
