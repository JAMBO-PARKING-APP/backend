import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF123D2F);
  static const Color primaryDark = Color(0xFF0A241C);
  static const Color primarySoft = Color(0xFF1C5A45);
  static const Color accentColor = Color(0xFFD4A24C);
  static const Color accentSoft = Color(0xFFE7C98A);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF6F4EE);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFBFAF7);
  static const Color textPrimary = Color(0xFF18201D);
  static const Color textSecondary = Color(0xFF66756F);
  static const Color borderColor = Color(0xFFE8E2D6);
  static const Color scaffoldMuted = Color(0xFFF6F4EE);

  static final ThemeData officerTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.manrope().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: primaryDark,
      error: errorColor,
      onError: Colors.white,
      surface: cardColor,
      onSurface: textPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: scaffoldMuted,
    textTheme: GoogleFonts.manropeTextTheme().copyWith(
      headlineLarge: GoogleFonts.manrope(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: primaryDark,
      contentTextStyle: GoogleFonts.manrope(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),
  );
}

