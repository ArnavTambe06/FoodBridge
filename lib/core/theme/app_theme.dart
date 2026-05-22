import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Surfaces
  static const surface = Color(0xFFFBF9F2);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F4ED);
  static const surfaceContainer = Color(0xFFF0EEE7);
  static const surfaceContainerHigh = Color(0xFFEAE8E1);
  static const surfaceContainerHighest = Color(0xFFE4E2DC);

  // Primary (Forest Green)
  static const primary = Color(0xFF456237);
  static const primaryContainer = Color(0xFF5D7B4E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFCAEDB6);

  // Secondary (Terracotta)
  static const secondary = Color(0xFF94492D);
  static const secondaryContainer = Color(0xFFFFDBCF);
  static const onSecondary = Color(0xFFFFFFFF);

  // Text
  static const onSurface = Color(0xFF1B1C18);
  static const onSurfaceVariant = Color(0xFF43483F);
  static const outline = Color(0xFFC3C8BC);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
      ),
      textTheme: TextTheme(
        // Headlines — Manrope
        displayLarge: GoogleFonts.manrope(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.02 * 36,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.02 * 28,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.02 * 24,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: -0.02 * 20,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        // Body — Inter
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: 0,
      ),
    );
  }
}