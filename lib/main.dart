import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  runApp(const FindStackApp());
}

class FindStackApp extends StatelessWidget {
  const FindStackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindStack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
