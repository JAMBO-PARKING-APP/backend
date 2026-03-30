import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Palette: White + Light Blue + Mantis Green
  static const Color primaryColor = Color(0xFF6BA3FF); // Modern Light Blue
  static const Color primaryDark = Color(0xFF4A90E2); // Deeper Light Blue
  static const Color accentColor = Color(0xFF52B788); // Mantis Green
  static const Color mantisGreen = Color(0xFF52B788); // Primary Green Accent

  static const Color successColor = Color(0xFF52B788); // Mantis Green
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color errorColor = Color(0xFFEF4444);

  // Neutral Colors (Light Theme) - Modern White Base
  static const Color textPrimary = Color(0xFF1A202C); // Dark Gray
  static const Color textSecondary = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0); // Subtle Light Border
  static const Color dividerColor = Color(0xFFF0F4F8); // Very light
  static const Color backgroundColor = Colors.white; // Pure White
  static const Color cardBackground = Color(0xFFFAFBFC); // Off-white

  // Dark Theme (Softened, not harsh)
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Navy-ish
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFCBD5F5);
  static const Color darkDividerColor = Color(0xFF334155);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: cardBackground,
      onSurface: textPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,

    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary,
      ),
    ),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: const BorderSide(color: primaryColor, width: 1.2),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFB), // Light neutral input
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );

  static ThemeData darkTheme = lightTheme.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: lightTheme.colorScheme.copyWith(
      brightness: Brightness.dark,
      surface: darkCardBackground,
      onSurface: darkTextPrimary,
    ),
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: darkBackgroundColor,
      foregroundColor: darkTextPrimary,
    ),
    cardTheme: lightTheme.cardTheme.copyWith(
      color: darkCardBackground,
    ),
    textTheme: lightTheme.textTheme.apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: darkCardBackground,
    ),
  );
}