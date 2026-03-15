import 'dart:math';
import 'package:flutter/material.dart';

/// A single floating particle with position, velocity, size, and opacity.
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });
}

/// Painter that renders floating particles with gentle motion.
class FloatingParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  final double globalOpacity;

  FloatingParticlesPainter({
    required this.particles,
    required this.color,
    required this.globalOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * globalOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}

/// Generates a list of random particles for a given screen size.
List<Particle> generateParticles(int count, double width, double height) {
  final random = Random();
  return List.generate(count, (_) {
    return Particle(
      x: random.nextDouble() * width,
      y: random.nextDouble() * height,
      vx: (random.nextDouble() - 0.5) * 0.4,
      vy: (random.nextDouble() - 0.5) * 0.3,
      radius: 1.5 + random.nextDouble() * 2.5,
      opacity: 0.15 + random.nextDouble() * 0.35,
    );
  });
}

/// Updates particle positions, wrapping around screen edges.
void updateParticles(List<Particle> particles, double width, double height) {
  for (final p in particles) {
    p.x += p.vx;
    p.y += p.vy;

    if (p.x < 0) p.x = width;
    if (p.x > width) p.x = 0;
    if (p.y < 0) p.y = height;
    if (p.y > height) p.y = 0;
  }
}
