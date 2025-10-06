import 'dart:async';
import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      print('[SplashScreen] 🔍 Checking auth state...');

      // Wait minimum 2 seconds untuk splash screen animation
      await Future.delayed(Duration(seconds: 2));

      // Try to recover session first
      final hasValidSession = await _authService.recoverSession();

      if (hasValidSession && _authService.isAuthenticated) {
        print(
          '[SplashScreen] ✅ User logged in: ${_authService.currentUser?.email}',
        );

        // Verify user profile exists in database
        final userProfile = await _authService.getCurrentUserProfile();

        if (userProfile != null) {
          print('[SplashScreen] ✅ User profile found, navigating to dashboard');
          // User is authenticated and has profile, go to dashboard
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        } else {
          print('[SplashScreen] ⚠️ User authenticated but no profile found');
          // User authenticated but no profile (edge case), logout and go to login
          await _authService.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        }
      } else {
        print('[SplashScreen] ❌ No valid session, navigating to onboarding');
        // No valid session, go to onboarding
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        }
      }
    } catch (e) {
      print('[SplashScreen] ❌ Error checking auth state: $e');
      // On error, go to onboarding for safety
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AFDYL',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.softBlack,
                      letterSpacing: 8.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Quran untuk Dyslexia',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.softBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
