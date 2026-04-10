import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/animation_config.dart';

class ProductivityPulseGauge extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String label;

  const ProductivityPulseGauge({
    super.key,
    required this.progress,
    this.label = 'Focus Score',
  });

  @override
  State<ProductivityPulseGauge> createState() => _ProductivityPulseGaugeState();
}

class _ProductivityPulseGaugeState extends State<ProductivityPulseGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.slowDuration * 2, // 800ms
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProductivityPulseGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: _animation.value,
                  primaryColor: theme.colorScheme.primary,
                  secondaryColor: theme.colorScheme.tertiary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_animation.value * 100).toInt()}%',
                  style: GoogleFonts.manrope(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth/2),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Progress track with gradient
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth/2);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.5),
          primaryColor,
          secondaryColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: math.pi * 0.75,
        endAngle: math.pi * (0.75 + 1.5),
        transform: GradientRotation(math.pi * 0.75),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw shadow/glow (simple version for performance)
    final shadowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeCap = StrokeCap.round;

    if (progress > 0.05) {
      canvas.drawArc(
        rect,
        math.pi * 0.75,
        math.pi * 1.5 * progress,
        false,
        shadowPaint,
      );
    }

    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
