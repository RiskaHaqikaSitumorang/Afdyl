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
import '../screens/profile_page.dart';
import '../screens/hijaiyah_tracing_page.dart' as tracing;
import '../screens/hijaiyah_tracing_detail_page.dart' as detail;
import '../screens/latihan_kata_page.dart' as latihan;
import '../screens/hijaiyah_recognition_game.dart';

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
  static const String profile = '/profile';
  static const String hijaiyahTracing = '/hijaiyah-tracing';
  static const String hijaiyahTracingDetail = '/hijaiyah-tracing-detail';
  static const String latihanKata = '/latihan-kata';
  static const String hijaiyahRecognition = '/hijaiyah-recognition';

  static final routes = <String, WidgetBuilder>{
    splash: (context) => SplashScreen(),
    onboarding: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    dashboard: (context) => DashboardScreen(),
    quran: (context) => QuranPage(),
    qibla: (context) => QiblaPage(),
    wrapped: (context) => QuranWrappedScreen(),
    profile: (context) => ProfilePage(),
    hijaiyahTracing: (context) => tracing.HijaiyahTracingPage(),
    hijaiyahTracingDetail:
        (context) =>
            detail.HijaiyahTracingDetailPage(letter: '', pronunciation: ''),
    reading: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ReadingPage(
        type: args?['type'] as String? ?? 'surah',
        number: args?['number'] as int? ?? 1,
        name: args?['name'] as String? ?? 'Default',
        initialAyah: args?['initialAyah'] as int?,
        initialWord: args?['initialWord'] as int?,
      );
    },
    latihanKata: (context) => latihan.LatihanKataPage(),
    hijaiyahRecognition: (context) => HijaiyahRecognitionGame(),
  };
}
