// lib/utils/navigation_helper.dart
import 'package:flutter/material.dart';

class NavigationHelper {
  static Future<T?> pushAndRefresh<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    Function? onReturn,
  }) async {
    final result = await Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );

    // Panggil callback jika ada
    if (onReturn != null) {
      onReturn();
    }

    return result;
  }
}
