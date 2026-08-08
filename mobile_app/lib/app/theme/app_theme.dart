import 'package:flutter/material.dart';

/// CampusCore brand colors
abstract final class AppColors {
  // Primary — deep teal
  static const Color primary      = Color(0xFF006B5E);
  static const Color primaryLight = Color(0xFF4CAF93);
  static const Color primaryDark  = Color(0xFF004D43);

  // Accent — warm amber
  static const Color accent      = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info    = Color(0xFF2563EB);

  // Text — high contrast
  static const Color textPrimary   = Color(0xFF0F172A); // near black
  static const Color textSecondary = Color(0xFF334155); // dark slate
  static const Color textHint      = Color(0xFF64748B); // medium slate

  // Backgrounds
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFE2E8F0);

  // Borders / dividers
  static const Color border = Color(0xFFCBD5E1);

  // Neutrals (kept for backward compat)
  static const Color grey50  = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey900 = Color(0xFF0F172A);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.surface,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.background,

      // Text theme — all text dark enough to read
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displaySmall:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
        bodyMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        bodySmall:     TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: AppColors.textSecondary),
        labelSmall:    TextStyle(color: AppColors.textSecondary),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          fontFamily: 'Nunito',
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Nunito',
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: 'Nunito',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Nunito'),
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.8,
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          fontFamily: 'Nunito',
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontFamily: 'Nunito',
        ),
        iconColor: AppColors.textSecondary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontFamily: 'Nunito',
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Nunito',
    );
  }
}
