import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.6,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? AppColors.surfaceVariant).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.outlineVariant,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
