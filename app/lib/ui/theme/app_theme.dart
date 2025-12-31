/// Combat-optimised application theme.
///
/// Designed for use under stress with:
/// - High contrast colours
/// - Large touch targets
/// - Glove-friendly sizing
/// - Night vision compatibility (dark mode)
///
/// Colour scheme inspired by Pj ASCLEPIUS branding:
/// - Cyan/teal primary accent
/// - Magenta/pink secondary
/// - Navy dark tones
library;

import 'package:flutter/material.dart';

/// Application theme configuration.
class AppTheme {
  AppTheme._();

  // --- Colour Palette (Pj ASCLEPIUS Branding) ---

  /// Primary dark background - deep navy
  static const Color backgroundDark = Color(0xFF0A1628);

  /// Surface colour for cards/containers
  static const Color surfaceDark = Color(0xFF12233D);

  /// Elevated surface
  static const Color surfaceElevated = Color(0xFF1A3050);

  /// Primary accent - cyan/teal from logo caduceus
  static const Color primaryAccent = Color(0xFF00D4E5);

  /// Secondary accent - magenta/pink from logo caduceus
  static const Color secondaryAccent = Color(0xFFE91E8C);

  /// Warning/caution
  static const Color warning = Color(0xFFFFAB00);

  /// Critical/danger - uses secondary magenta
  static const Color danger = Color(0xFFE91E8C);

  /// Information - uses primary cyan
  static const Color info = Color(0xFF00D4E5);

  /// Text colours
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C5D6);
  static const Color textMuted = Color(0xFF6B7D94);
  
  // --- Triage Category Colours ---
  
  static const Color triageP1 = Color(0xFFFF1744); // Red - Immediate
  static const Color triageP2 = Color(0xFFFF9100); // Orange - Urgent
  static const Color triageP3 = Color(0xFF00E676); // Green - Delayed
  static const Color triageDead = Color(0xFF424242); // Grey - Dead
  
  // --- MARCH Component Colours (branded) ---

  static const Color marchM = Color(0xFFE91E8C); // Magenta - Massive bleeding
  static const Color marchA = Color(0xFF00D4E5); // Cyan - Airway
  static const Color marchR = Color(0xFF00B4D8); // Teal - Respiratory
  static const Color marchC = Color(0xFFFFAB00); // Amber - Circulation
  static const Color marchH = Color(0xFFAF52DE); // Purple - Head/Hypothermia

  // --- Content Box Types (Aide Memoire colours) ---

  /// Action box - steps to perform (Blue)
  static const Color boxAction = Color(0xFF0066CC);

  /// Advice box - guidance/information (Yellow/Amber)
  static const Color boxAdvice = Color(0xFFFFCC00);

  /// Warning box - critical safety info (Red)
  static const Color boxWarning = Color(0xFFCC0000);

  // --- Sizing (Combat-friendly) ---
  
  /// Minimum touch target size (48dp Android guideline, we use larger)
  static const double minTouchTarget = 56.0;
  
  /// Large button height for gloved use
  static const double largeButtonHeight = 64.0;
  
  /// Extra large button for critical actions
  static const double xlButtonHeight = 80.0;
  
  /// Standard padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  /// Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  // --- Typography ---
  
  static const String fontFamily = 'Roboto';
  
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  // --- Theme Data ---
  
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryAccent,
      secondary: secondaryAccent,
      tertiary: info,
      surface: surfaceDark,
      error: danger,
      onPrimary: backgroundDark,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineSmall,
    ),
    
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: backgroundDark,
        minimumSize: const Size(double.infinity, largeButtonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: buttonText,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(double.infinity, largeButtonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        side: const BorderSide(color: textMuted, width: 1.5),
        textStyle: buttonText,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryAccent,
        minimumSize: const Size(minTouchTarget, minTouchTarget),
        textStyle: labelLarge,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      contentPadding: const EdgeInsets.all(paddingMedium),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      labelStyle: bodyMedium,
      hintStyle: bodyMedium.copyWith(color: textMuted),
    ),
    
    dividerTheme: const DividerThemeData(
      color: surfaceElevated,
      thickness: 1,
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
  
  // --- Helper Methods ---
  
  /// Get colour for triage category.
  static Color getTriageCategoryColor(String category) {
    return switch (category.toUpperCase()) {
      'P1' => triageP1,
      'P2' => triageP2,
      'P3' => triageP3,
      'DEAD' => triageDead,
      _ => textMuted,
    };
  }
  
  /// Get colour for MARCH component.
  static Color getMarchComponentColor(String component) {
    return switch (component.toUpperCase()) {
      'M' => marchM,
      'A' => marchA,
      'R' => marchR,
      'C' => marchC,
      'H' => marchH,
      _ => textMuted,
    };
  }

  /// Get colour for content box type.
  static Color getBoxTypeColor(String boxType) {
    return switch (boxType.toLowerCase()) {
      'action' => boxAction,
      'advice' => boxAdvice,
      'warning' => boxWarning,
      _ => surfaceElevated,
    };
  }

  /// Get text colour for content box (ensures contrast).
  static Color getBoxTextColor(String boxType) {
    return switch (boxType.toLowerCase()) {
      'advice' => backgroundDark, // Dark text on yellow
      _ => textPrimary, // White text on blue/red
    };
  }
}
