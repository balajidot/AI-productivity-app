import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CelebrationOverlay {
  static void show(BuildContext context) {
    HapticFeedback.heavyImpact();

    final overlay = OverlayEntry(
      builder: (context) => const _CelebrationWidget(),
    );

    Overlay.of(context).insert(overlay);

    Future.delayed(const Duration(milliseconds: 900), () {
      overlay.remove();
    });
  }
}

class _CelebrationWidget extends StatefulWidget {
  const _CelebrationWidget();

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particles = List.generate(30, (_) => _ConfettiParticle(_random));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // Center checkmark
              Center(
                child: Opacity(
                  opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.5 + (_controller.value * 1.5),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              // Confetti particles
              ..._particles.map((p) => _buildParticle(p, context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticle(_ConfettiParticle p, BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final centerX = screenW / 2;
    final centerY = screenH / 2;

    final progress = _controller.value;
    final x = centerX + (p.directionX * progress * p.speed);
    final y = centerY + (p.directionY * progress * p.speed) + (progress * progress * 200);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final rotation = progress * p.rotationSpeed;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: p.size,
            height: p.size * 0.6,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double directionX;
  final double directionY;
  final double speed;
  final double size;
  final double rotationSpeed;
  final Color color;

  _ConfettiParticle(Random random)
      : directionX = (random.nextDouble() - 0.5) * 2,
        directionY = (random.nextDouble() - 0.8) * 2,
        speed = 150 + random.nextDouble() * 250,
        size = 6 + random.nextDouble() * 8,
        rotationSpeed = (random.nextDouble() - 0.5) * 10,
        color = [
          const Color(0xFFA5A5FF),
          const Color(0xFFFFA1D5),
          const Color(0xFFA790FE),
          const Color(0xFF9596FF),
          const Color(0xFFFFD700),
          const Color(0xFF00E5FF),
        ][random.nextInt(6)];
}
