import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF0E0E0E);
  
  // Tonal Surfaces (Design Mandate: Tonal Transitions)
  static const Color surfaceLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1919);
  static const Color surfaceHighest = Color(0xFF262626);
  static const Color surfaceVariant = Color(0xFF262626);
  static const Color surfaceBright = Color(0xFF2C2C2C);
  
  // Brand Colors
  static const Color primary = Color(0xFFA5A5FF);
  static const Color primaryContainer = Color(0xFF9596FF);
  static const Color secondary = Color(0xFFA790FE);
  static const Color tertiary = Color(0xFFFFA1D5);
  static const Color error = Color(0xFFFF6E84);
  static const Color errorDim = Color(0xFFD73357);
  
  // Content Colors
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFADAAAA);
  static const Color outline = Color(0xFF767575);
  static const Color outlineVariant = Color(0x26484847); // 15% opacity as per "Ghost Border" rule
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    transform: GradientRotation(135 * 3.14159 / 180),
  );
}
