// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

/// AFDYL App Color Design System
/// Color palette untuk konsistensi desain di seluruh aplikasi
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // === PRIMARY COLOR SYSTEM ===

  /// Primary Color - Warm Beige
  /// #EDD1B0 - Warna utama aplikasi
  static const Color primary = Color(0xFFEDD1B0);

  /// Secondary Color - Golden Yellow
  /// #EDDD6E - Warna sekunder untuk aksen
  static const Color secondary = Color(0xFFEDDD6E);

  /// Tertiary Color - Orange
  /// #E37100 - Warna tersier untuk highlight
  static const Color tertiary = Color(0xFFE37100);

  /// Accent Yellow
  /// #F8FD89 - Kuning cerah untuk elemen penting
  static const Color yellow = Color(0xFFF8FD89);

  // === SHADES & TINTS ===

  /// Primary color variations
  static const Color primaryLight = Color(0xFFF5E5D0);
  static const Color primaryDark = Color(0xFFE5C190);

  /// Secondary color variations
  static const Color secondaryLight = Color(0xFFF1E68E);
  static const Color secondaryDark = Color(0xFFE9D54E);

  /// Tertiary color variations
  static const Color tertiaryLight = Color(0xFFE98B33);
  static const Color tertiaryDark = Color(0xFFCC5C00);

  // === NEUTRAL COLORS ===

  /// White and off-white colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFFDFFF2);
  static const Color offWhite = Color(0xFFFAF8F5);

  /// Gray scale
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);

  /// Black variations
  static const Color black = Color(0xFF000000);
  static const Color softBlack = Color(0xFF1A1A1A);

  // === SEMANTIC COLORS ===

  /// Success colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);

  /// Error colors
  static const Color error = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  /// Warning colors
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  /// Info colors
  static const Color info = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  /// Dark colors
  static const Color blackPrimary = Color(0xFF161616);

  // === BACKGROUND GRADIENTS ===

  /// Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  /// Tertiary gradient
  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiary, tertiaryLight],
  );

  // === SURFACE COLORS ===

  /// Card and container colors
  static const Color surface = whiteSoft;
  static const Color surfaceVariant = Color(0xFFF7F3EF);

  /// Elevated surface colors
  static const Color elevation1 = Color(0xFFFFFDF9);
  static const Color elevation2 = Color(0xFFFFFCF8);

  // === TEXT COLORS ===

  /// Primary text colors
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textTertiary = Color(0xFF8A8A8A);

  /// Text on colored backgrounds
  static const Color textOnPrimary = Color(0xFF2C2C2C);
  static const Color textOnSecondary = Color(0xFF2C2C2C);
  static const Color textOnTertiary = Color(0xFFFFFFFF);
  static const Color textOnYellow = Color(0xFF2C2C2C);

  // === UTILITY METHODS ===

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get primary color with custom opacity
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }

  /// Get secondary color with custom opacity
  static Color secondaryWithOpacity(double opacity) {
    return secondary.withOpacity(opacity);
  }

  /// Get tertiary color with custom opacity
  static Color tertiaryWithOpacity(double opacity) {
    return tertiary.withOpacity(opacity);
  }

  // === SHADOW COLORS ===

  /// Standard shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.12);
  static Color shadowDark = Colors.black.withOpacity(0.16);

  /// Colored shadows
  static Color primaryShadow = primary.withOpacity(0.25);
  static Color secondaryShadow = secondary.withOpacity(0.25);
  static Color tertiaryShadow = tertiary.withOpacity(0.25);
}

/// Extension untuk kemudahan penggunaan warna
extension AppColorsExtension on Color {
  /// Get color with custom opacity
  Color withCustomOpacity(double opacity) {
    return withOpacity(opacity);
  }
}

/// Theme-specific color schemes
class AppColorScheme {
  /// Light theme color scheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnSecondary,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.textOnTertiary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.whiteSoft,
    outline: AppColors.gray,
    background: AppColors.whiteSoft,
    onBackground: AppColors.textPrimary,
    surfaceVariant: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
  );
}
