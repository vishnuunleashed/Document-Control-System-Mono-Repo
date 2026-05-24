import 'package:flutter/material';
import 'routes/app_routes.dart';

class DCSApp extends StatelessWidget {
  const DCSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Document Control System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Dark Slate/Navy
          primary: const Color(0xFF2563EB),   // Royal Blue
          secondary: const Color(0xFF10B981), // Emerald
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF3B82F6),
          secondary: const Color(0xFF34D399),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: AppRoutes.router,
    );
  }
}
