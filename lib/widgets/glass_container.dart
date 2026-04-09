import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class GlassContainer extends ConsumerWidget {
  static const bool enableBlur = true; // Global toggle for performance tuning

  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool useBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0, // Optimized for performance/battery
    this.opacity = 0.6,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowPerformance = ref.watch(performanceModeProvider);

    // Background colors
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.surfaceContainer).withValues(alpha: isLowPerformance ? opacity + 0.15 : opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isLowPerformance ? 0.8 : 0.6),
          width: 1.0,
        ),
        boxShadow: isLowPerformance ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle inner highlight - hidden in low performance mode to save draw calls
          if (!isLowPerformance)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    if (isLowPerformance || !enableBlur || !useBlur || blur <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
