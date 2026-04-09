import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF0C0C0E);
  
  // Tonal Surfaces (Enhanced for visibility)
  static const Color surfaceLow = Color(0xFF141417);
  static const Color surfaceContainer = Color(0xFF1C1C1F);
  static const Color surfaceHighest = Color(0xFF2C2C2F);
  static const Color surfaceVariant = Color(0xFF2C2C2F);
  static const Color surfaceBright = Color(0xFF323235);
  
  // Brand Colors
  static const Color primary = Color(0xFFA5A5FF);
  static const Color primaryContainer = Color(0xFF9596FF);
  static const Color secondary = Color(0xFFA790FE);
  static const Color tertiary = Color(0xFFFFA1D5);
  static const Color error = Color(0xFFFF6E84);
  static const Color errorDim = Color(0xFFD73357);
  
  // Content Colors
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB0B0B5);
  static const Color outline = Color(0xFF48484A);
  static const Color outlineVariant = Color(0x6048484A); // Increased to ~37% opacity
  static const Color lightOutlineVariant = Color(0x1F000000); // 12% Black for Light Mode

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF9F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF1F1F7);
  static const Color lightOnSurface = Color(0xFF1A1A1C);
  static const Color lightOnSurfaceVariant = Color(0xFF6B6A71);
  static const Color lightPrimary = Color(0xFF5D5FEF);
  static const Color lightSecondary = Color(0xFF7B61FF);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    transform: GradientRotation(135 * 3.14159 / 180),
  );
}
