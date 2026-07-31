import 'package:flutter/material.dart';

class AdminColors {
  static const Color primary = Color(0xFF006B5E);
  static const Color sidebar = Color(0xFF1A2332);
  static const Color sidebarSelected = Color(0xFF006B5E);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Colors.white;
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey900 = Color(0xFF111827);
}

class AdminTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.primary,
        brightness: Brightness.light,
        background: AdminColors.background,
        surface: AdminColors.surface,
      ),
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AdminColors.background,
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.grey900,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
