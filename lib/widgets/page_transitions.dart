import 'package:flutter/material.dart';

class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => page,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Mulai dari kanan
                end: Offset.zero, // Berakhir di tengah
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

class SlideLeftRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideLeftRoute({required this.page})
    : super(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => page,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0), // Mulai dari kiri
                end: Offset.zero, // Berakhir di tengah
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
    : super(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => page,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Mulai dari bawah
                end: Offset.zero, // Berakhir di tengah
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}

class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
    : super(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => page,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

// Extension untuk memudahkan navigasi dengan animasi
extension NavigationExtension on BuildContext {
  // Navigate dengan slide dari kanan
  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(SlideRightRoute<T>(page: page));
  }

  // Navigate dengan slide dari kiri
  Future<T?> pushSlideLeft<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(SlideLeftRoute<T>(page: page));
  }

  // Navigate dengan slide dari bawah
  Future<T?> pushSlideUp<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpRoute<T>(page: page));
  }

  // Navigate dengan fade
  Future<T?> pushFade<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(FadeRoute<T>(page: page));
  }

  // Replace dengan slide dari kanan
  Future<T?> pushReplacementSlideRight<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(
      this,
    ).pushReplacement<T, TO>(SlideRightRoute<T>(page: page), result: result);
  }
}
