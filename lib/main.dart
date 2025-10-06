import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_routes.dart';
import 'constants/app_colors.dart';
import 'services/deep_link_service.dart';
import 'dart:async';

void main() async {
  // Wrap everything in error boundary
  await runZonedGuarded<Future<void>>(
    () async {
      print('🚀🚀🚀 [MAIN] APP STARTING 🚀🚀🚀');
      WidgetsFlutterBinding.ensureInitialized();

      // Setup global error handlers
      FlutterError.onError = (FlutterErrorDetails details) {
        print('❌ [FLUTTER ERROR] ${details.exception}');
        print('Stack trace: ${details.stack}');
        FlutterError.presentError(details);
      };

      // Custom error widget builder for release mode
      ErrorWidget.builder = (FlutterErrorDetails details) {
        print('❌ [ERROR WIDGET] ${details.exception}');
        return MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 24),
                    Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      kDebugMode
                          ? details.exception.toString()
                          : 'Aplikasi mengalami masalah. Silakan restart aplikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    SizedBox(height: 24),
                    if (kDebugMode)
                      Text(
                        details.stack.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      };

      // Load environment variables with error handling
      try {
        print('[MAIN] Loading environment variables...');
        await dotenv.load();
        print('[MAIN] ✅ Environment variables loaded');
      } catch (e) {
        print('[MAIN] ⚠️ Error loading .env file: $e');
        // Continue anyway, might be using default values
      }

      // Initialize Supabase with error handling
      try {
        print('[MAIN] Initializing Supabase...');
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
        print('[MAIN] ✅ Supabase initialized');
      } catch (e) {
        print('[MAIN] ⚠️ Error initializing Supabase: $e');
        // Continue anyway, app can work without Supabase
      }

      print('[MAIN] Running app...');
      runApp(const MyApp());
      print('[MAIN] ✅ App started');
    },
    (error, stack) {
      // Catch any errors not caught by Flutter framework
      print('❌ [UNCAUGHT ERROR] $error');
      print('Stack trace: $stack');
    },
  );
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Global navigator key untuk deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep link handler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.initialize();
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add global navigator key
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
      // Add builder to catch errors in widget tree
      builder: (context, widget) {
        // Wrap entire app with error boundary
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorScreen(errorDetails: errorDetails);
        };
        return widget ?? SizedBox.shrink();
      },
    );
  }
}

// Error Screen Widget
class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorScreen({Key? key, required this.errorDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 24),
                Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  kDebugMode
                      ? errorDetails.exception.toString()
                      : 'Aplikasi mengalami masalah. Silakan restart aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        errorDetails.stack.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
