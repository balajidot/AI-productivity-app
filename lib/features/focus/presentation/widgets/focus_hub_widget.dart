import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusHubWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final String subLabel;

  const FocusHubWidget({
    super.key,
    required this.progress,
    this.label = 'Productivity',
    this.subLabel = 'Daily Flow',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 120,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RadialPainter(
                          progress: value,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        Text(
                          '${(value * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            subLabel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RadialPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    final paintBase = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw background arc
    canvas.drawArc(rect, startAngle, sweepAngle, false, paintBase);

    // Draw progress arc
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, paintProgress);
  }


  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}
