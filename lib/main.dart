// What is this file for?
// Starts the Pocket Jinn app and gives it the shared light and dark themes.

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'services/llm_service.dart';
import 'screens/home_screen.dart';

/// Entry point of the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LlmService.initialize();
  runApp(const PocketJinnApp());
}

/// The root widget that sets the title, themes and first screen.
class PocketJinnApp extends StatelessWidget {
  const PocketJinnApp({super.key});

  /// Builds the MaterialApp with automatic light and dark mode.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
