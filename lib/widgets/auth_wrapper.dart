import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_routes.dart';

/// Auth wrapper to handle automatic navigation based on auth state changes
/// This can be used to automatically redirect users when they login/logout
class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      print('[AuthWrapper] Auth state changed: $event');

      // Handle different auth events
      switch (event) {
        case AuthChangeEvent.signedIn:
          print('[AuthWrapper] User signed in');
          // User signed in - could navigate to dashboard
          // But we'll let splash screen handle initial navigation
          break;

        case AuthChangeEvent.signedOut:
          print('[AuthWrapper] User signed out, navigating to login');
          // User signed out - navigate to login
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          }
          break;

        case AuthChangeEvent.tokenRefreshed:
          print('[AuthWrapper] Token refreshed successfully');
          break;

        case AuthChangeEvent.passwordRecovery:
          print('[AuthWrapper] Password recovery initiated');
          // Will be handled by deep link service
          break;

        case AuthChangeEvent.userUpdated:
          print('[AuthWrapper] User data updated');
          break;

        default:
          print('[AuthWrapper] Unhandled auth event: $event');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
