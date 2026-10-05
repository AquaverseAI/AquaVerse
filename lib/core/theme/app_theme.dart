import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralised Material 3 theme for AquaVerse AI.
/// Light theme — strictly implementing AquaVerse_AI_Design_System.md
class AppTheme {
  // Legacy constants kept for backward compatibility with existing widgets.
  // New code should use AppRadius and AppSpacing from app_spacing.dart.
  static const double cardRadius   = 16.0;   // = AppRadius.card
  static const double buttonRadius = 14.0;   // = AppRadius.button
  static const double inputRadius  = 12.0;   // = AppRadius.sm
  static const double pageMargin   = 16.0;   // = AppSpacing.lg
  static const double buttonHeight = 48.0;   // = AppTouchTarget.buttonHeight


  /// Returns the correct body text line-height for tall Indic scripts.
  /// Tamil (ta), Telugu (te), Kannada (kn), and Malayalam (ml) glyphs
  /// have ascenders/descenders that clip at the standard 1.5 height.
  ///
  /// Usage: height: AppTheme.bodyLineHeight(Localizations.localeOf(context))
  static double bodyLineHeight(Locale? locale) {
    const tallScripts = {'ta', 'te', 'kn', 'ml'};
    if (locale != null && tallScripts.contains(locale.languageCode)) {
      return 1.65;
    }
    return 1.5;
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    const palatino = 'Palatino';
    const palatinoFallbacks = ['Palatino Linotype', 'Georgia', 'serif'];

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary500,
      colorScheme: const ColorScheme.light(
        primary:   AppColors.primary500,
        secondary: AppColors.green600,
        tertiary:  AppColors.primary300,
        surface:   AppColors.surface,
        error:     AppColors.critical,
        onPrimary:   Colors.white,
        onSecondary: Colors.white,
        onSurface:   AppColors.textPrimary,
      ),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Input ───────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.critical),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.critical, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),

      // ── Primary Button (ElevatedButton) ─────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Secondary Button (OutlinedButton) ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary800,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Ghost Button (TextButton) ───────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary700,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── BottomNavigationBar ─────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary700,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── Text ────────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
        headlineLarge: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
        headlineMedium: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
        bodySmall: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4),
        labelLarge: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: palatino, fontFamilyFallback: palatinoFallbacks, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
      ),

      // ── Icon ────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.mountain700, size: 20),
    );
  }
}
