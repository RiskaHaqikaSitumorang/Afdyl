import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import untuk akses navigatorKey

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize deep link listener
  Future<void> initialize() async {
    try {
      // Handle the initial link that opened the app
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // Listen to incoming links while the app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('Error handling deep link: $err');
        },
      );
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
    }
  }

  // Handle deep link navigation
  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Tunggu sebentar untuk memastikan navigator sudah siap
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('Navigator context not ready yet');
        return;
      }

      // Check if it's a password reset link
      if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
        debugPrint('Navigating to reset password screen...');
        // Navigate to reset password screen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      }
      // You can add more deep link handlers here
      else if (uri.host == 'verify-email' ||
          uri.path.contains('verify-email')) {
        // Handle email verification
        debugPrint('Email verification link detected');
      }
    });
  }

  // Dispose the subscription
  void dispose() {
    _linkSubscription?.cancel();
  }
}
