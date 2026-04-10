import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimationConfig {
  /// Ultra-fast duration for professional transitions (100ms)
  static const Duration standardDuration = Duration(milliseconds: 100);
  
  /// Near-instant duration for quick UI feedback (50ms)
  static const Duration fastDuration = Duration(milliseconds: 50);
  
  /// Standard slow duration (250ms)
  static const Duration slowDuration = Duration(milliseconds: 250);

  /// Minimal slide offset (0.005)
  static const Offset subtleSlide = Offset(0, 0.005);
  
  /// Minimal slide offset for X-axis (0.01)
  static const Offset subtleSlideX = Offset(0.01, 0);

  /// Curve for professional, smooth transitions
  static const Curve professionalCurve = Curves.easeOutCubic;

  /// Default delay for list items to avoid pop-in feel (50ms)
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Utility to get standard animation setup
  static Animate standardFade(Widget child, {Duration? delay}) {
    return child.animate(delay: delay).fadeIn(
      duration: standardDuration,
      curve: professionalCurve,
    );
  }
}
