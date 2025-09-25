import 'package:flutter/material.dart';

class ArabicTextStyles {
  // Base Arabic text style with Maqroo font
  static const TextStyle base = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 24,
    color: Colors.black87,
  );

  // Different sizes for Arabic text
  static const TextStyle small = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 18,
    color: Colors.black87,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 28,
    color: Colors.black87,
  );

  static const TextStyle large = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 40,
    color: Colors.black87,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle extraLarge = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 56,
    color: Colors.black87,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle huge = TextStyle(
    fontFamily: 'Maqroo',
    fontSize: 72,
    color: Colors.black87,
    fontWeight: FontWeight.w700,
  );

  // Helper method to create custom Arabic text style
  static TextStyle custom({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? opacity,
  }) {
    return TextStyle(
      fontFamily: 'Maqroo',
      fontSize: fontSize ?? 24,
      color:
          opacity != null
              ? (color ?? Colors.black87).withOpacity(opacity)
              : (color ?? Colors.black87),
      fontWeight: fontWeight,
    );
  }
}
