// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/quran_page.dart';
import '../screens/qibla_page.dart';
import '../screens/reading_page.dart';
import '../screens/wrapped_screen.dart';
<<<<<<< HEAD
import '../screens/profile_page.dart';
=======
import '../screens/hijaiyah_tracing_page.dart';
>>>>>>> 184dea7722f6850644f6058b94078a9695846da2

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String quran = '/quran';
  static const String reading = '/reading';
  static const String qibla = '/qibla';
  static const String wrapped = '/wrapped';
<<<<<<< HEAD
  static const String profile = '/profile';

=======
  static const String hijaiyahTracing = '/hijaiyah-tracing'; // Pastikan didefinisikan
>>>>>>> 184dea7722f6850644f6058b94078a9695846da2

  static final routes = {
    splash: (context) => SplashScreen(),
    onboarding: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    dashboard: (context) => DashboardScreen(),
    quran: (context) => QuranPage(),
    qibla: (context) => QiblaPage(),
    wrapped: (context) => QuranWrappedScreen(),
<<<<<<< HEAD
    profile: (context) => ProfilePage(),
=======
    hijaiyahTracing: (context) => HijaiyahTracingPage(),
>>>>>>> 184dea7722f6850644f6058b94078a9695846da2
    reading: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ReadingPage(
        type: args?['type'] as String? ?? 'surah',
        number: args?['number'] as int? ?? 1,
        name: args?['name'] as String? ?? 'Default',
      );
    },
  };
}