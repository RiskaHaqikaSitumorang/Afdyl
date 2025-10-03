import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_routes.dart';
import 'constants/app_colors.dart';

void main() async {
  print('🚀🚀🚀 [MAIN] APP STARTING 🚀🚀🚀');
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  print('[MAIN] Loading environment variables...');
  await dotenv.load();
  print('[MAIN] ✅ Environment variables loaded');

  // Initialize Supabase
  print('[MAIN] Initializing Supabase...');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  print('[MAIN] ✅ Supabase initialized');

  print('[MAIN] Running app...');
  runApp(const MyApp());
  print('[MAIN] ✅ App started');
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFDYL',
      theme: ThemeData(
        fontFamily: 'OpenDyslexic',
        colorScheme: AppColorScheme.lightScheme,
        scaffoldBackgroundColor: AppColors.whiteSoft,
        primaryColor: AppColors.primary,
        useMaterial3: true,
        // Set global cursor color to black
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
    );
  }
}
