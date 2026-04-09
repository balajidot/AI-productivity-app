import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFA790FE);
  static const Color secondary = Color(0xFFFFA1D5);
  static const Color accent = Color(0xFF00E5FF);
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color outline = Color(0xFF334155);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF7C3AED)],
  );
}
