import 'package:flutter/material.dart';
import 'core/constants/constants.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
  runApp(const FindMyTeamApp());
}

class FindMyTeamApp extends StatelessWidget {
  const FindMyTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find My Team',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashScreen(),
    );
  }
}
