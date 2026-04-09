import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
      
      // Components
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
