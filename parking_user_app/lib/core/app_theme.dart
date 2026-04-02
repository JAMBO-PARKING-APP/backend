import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============= PRIMARY COLORS =============
  // Professional Blue - Primary brand color (matching officer app)
  static const Color primaryColor = Color(0xFF0078D4); // Windows Blue (matching officer app)
  static const Color primaryLight = Color(0xFFCCE5FF); // Light Blue background
  static const Color primaryDark = Color(0xFF005A9E); // Dark Blue for depth (matching officer app)

  // ============= SECONDARY COLORS =============
  // Modern Blue - Secondary brand color (matching officer app)
  static const Color accentColor = Color(0xFF00B4F0); // Light Blue (matching officer app)
  static const Color successColor = Color(0xFF10B981); // Success Green (matching officer app)
  static const Color mantisGreen = Color(0xFF10B981); // Primary Green Accent (matching officer app)
  static const Color secondaryLight = Color(0xFFCCF5EE); // Light Green background

  // ============= STATUS COLORS =============
  static const Color warningColor = Color(0xFFF59E0B); // Warm Orange (matching officer app)
  static const Color infoColor = Color(0xFF0078D4); // Same as primary (matching officer app)
  static const Color errorColor = Color(0xFFEF4444); // Bright Red (matching officer app)
  static const Color tertiary = Color(0xFFEF4444); // Modern Red/Coral (matching officer app)
  static const Color tertiaryLight = Color(0xFFFFCCCC); // Light Coral

  // ============= TEXT COLORS =============
  static const Color textPrimary = Color(0xFF121212); // True Black (matching officer app)
  static const Color textSecondary = Color(0xFF64748B); // Medium gray (matching officer app)
  static const Color textTertiary = Color(0xFF999999); // Light gray (for hints)
  static const Color textPlaceholder = Color(0xFFCCCCCC); // Placeholder text

  // ============= BACKGROUND & SURFACE COLORS =============
  static const Color backgroundColor = Colors.white; // Pure white background (matching officer app)
  static const Color cardBackground = Colors.white; // Pure white cards (matching officer app)
  static const Color surfaceLight = Color(0xFFF9FAFB); // Light surface (matching officer app)
  static const Color borderColor = Color(0xFFE5E7EB); // Border color (matching officer app)
  static const Color dividerColor = Color(0xFFF0F0F0); // Divider color
  
  // Additional surface colors for better contrast
  static const Color surfaceColor = Color(0xFFF8F9FA); // Very light gray surface
  static const Color surfaceVariant = Color(0xFFF1F3F4); // Light variant surface

  // ============= DARK THEME COLORS =============
  static const Color darkBackgroundColor = Color(0xFF121212); // Dark background
  static const Color darkCardBackground = Color(0xFF1E1E1E); // Dark cards
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White text
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Gray text
  static const Color darkDividerColor = Color(0xFF333333); // Dark dividers

  // Spacing Constants (for consistency)
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Border Radius Constants
  static const double radiusXS = 8;
  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 20;
  static const double radiusXL = 28;

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
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
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
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: textSecondary,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        color: textSecondary,
        fontWeight: FontWeight.w400,
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
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: const StadiumBorder(),
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      elevation: 4,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: cardBackground,
      selectedColor: primaryLight,
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusS),
        side: const BorderSide(color: borderColor),
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

  // Modern Design Utilities
  static BoxDecoration modernCardDecoration({
    Color? color,
    double? borderRadius,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration modernGradientDecoration({
    Color? startColor,
    Color? endColor,
    double? borderRadius,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: [
          startColor ?? primaryColor,
          endColor ?? primaryDark,
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      boxShadow: [
        BoxShadow(
          color: (startColor ?? primaryColor).withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration modernButtonDecoration({
    required Color color,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusS),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}