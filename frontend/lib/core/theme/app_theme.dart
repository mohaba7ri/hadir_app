import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette
  static const Color primaryTeal = Color(0xFF447C7B);
  static const Color primaryGold = Color(0xFFCAA24D);
  static const Color secondaryGold = Color(0xFFC9B27C);
  static const Color backgroundLight = Color(0xFFECF8F3);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Janat',
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,

      // Remove all shadows by default
      shadowColor: Colors.transparent,

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTeal),
        titleTextStyle: TextStyle(
          fontFamily: 'Janat',
          fontSize: 17, // iOS style title size
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(color: borderLight, width: 0.5),
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: primaryTeal,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),

      // Apple-style Flat Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Janat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
          textStyle: TextStyle(
            fontFamily: 'Janat',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Flat containers (Cards replacement)
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderLight, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration (Flat & Subtle)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(
            0xFFE9E9EB), // Slightly darker than surface for contrast
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: textSecondary, fontSize: 15),
        labelStyle: TextStyle(color: textPrimary, fontSize: 15),
      ),

      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        color: borderLight,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        titleTextStyle: TextStyle(
          fontFamily: 'Janat',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Janat',
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Janat',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Janat',
          fontSize: 16,
          color: textPrimary,
        ),
      ),
    );
  }
}
