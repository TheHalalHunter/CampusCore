import 'package:flutter/material.dart';

/// CampusCore brand colors — derived from the official app icon.
class AppColors {
  // ── Core brand blues ─────────────────────────────────────────────────────
  static const Color navyDark    = Color(0xFF0A1628); // icon bg / AppBar
  static const Color navyMid     = Color(0xFF0D2A6E); // sidebar
  static const Color primary     = Color(0xFF1565C0); // main blue
  static const Color primaryLight= Color(0xFF2196F3); // bright blue
  static const Color cyan        = Color(0xFF00B4D8); // cyan accent
  static const Color cyanBright  = Color(0xFF00D4FF); // pixel cyan
  static const Color coreBlue    = Color(0xFF4FC3F7); // "Core" wordmark

  // ── Kept for screens that reference secondary / accent ────────────────────
  static const Color secondary   = Color(0xFF2196F3); // alias for primaryLight
  static const Color accent      = Color(0xFF00B4D8); // alias for cyan

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info    = Color(0xFF2196F3);

  // ── Backgrounds & surfaces ────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFE3EBF8);
  static const Color border     = Color(0xFFBDD0F0);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF1E3A5F);
  static const Color textHint      = Color(0xFF64748B);
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnDarkSub = Color(0xFFB0C4DE);

  // ── Grey scale ────────────────────────────────────────────────────────────
  static const Color grey50  = Color(0xFFF0F4FF);
  static const Color grey100 = Color(0xFFE3EBF8);
  static const Color grey200 = Color(0xFFCDD8EF);
  static const Color grey300 = Color(0xFFB0C4DE);
  static const Color grey400 = Color(0xFF90A4C0);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF1E3A5F);
  static const Color grey800 = Color(0xFF0D2A6E);
  static const Color grey900 = Color(0xFF0A1628);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Medal colors (leaderboard) ────────────────────────────────────────────
  static const Color gold   = Color(0xFFFFD700);
  static const Color bronze = Color(0xFFCD7F32);

  // ── Shadows ───────────────────────────────────────────────────────────────
  /// Soft upward shadow used on sticky bottom bars and floating surfaces.
  static const Color shadow = Color(0x14000000);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [navyDark, navyMid, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        headlineMedium:TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        bodyLarge:     TextStyle(fontSize: 16, color: AppColors.textPrimary,   height: 1.6, fontFamily: 'Nunito'),
        bodyMedium:    TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontFamily: 'Nunito'),
        bodySmall:     TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Nunito'),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        labelMedium:   TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Nunito'),
        labelSmall:    TextStyle(fontSize: 11, color: AppColors.textHint,      fontFamily: 'Nunito'),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito'),
        hintStyle:  const TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
        prefixIconColor: AppColors.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.8),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontFamily: 'Nunito'),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
    );
  }
}
