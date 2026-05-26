import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/glass_tokens.dart';

/// Three animated colour orbs that form the persistent mesh background.
///
/// Sits at the very bottom of [AppScaffold]'s stack. The orbs drift slowly
/// using a simple sine-wave animation so the background feels alive without
/// consuming significant GPU time.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"AppMeshBackground".
class AppMeshBackground extends StatefulWidget {
  const AppMeshBackground({super.key});

  @override
  State<AppMeshBackground> createState() => _AppMeshBackgroundState();
}

class _AppMeshBackgroundState extends State<AppMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * 2 * math.pi;
        return CustomPaint(
          painter: _MeshPainter(
            t: t,
            opacity: tokens.meshOpacity,
            colorA: cs.primary,
            colorB: cs.tertiary,
            colorC: AppColors.info,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter({
    required this.t,
    required this.opacity,
    required this.colorA,
    required this.colorB,
    required this.colorC,
  });

  final double t;
  final double opacity;
  final Color colorA;
  final Color colorB;
  final Color colorC;

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Color color, double cx, double cy, double r) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(cx * size.width, cy * size.height),
          radius: r * size.width,
        ));
      canvas.drawCircle(
        Offset(cx * size.width, cy * size.height),
        r * size.width,
        paint,
      );
    }

    // Orb A — top-left, slow drift
    orb(colorA, 0.15 + 0.08 * math.sin(t * 0.7), 0.2 + 0.06 * math.cos(t * 0.5), 0.55);
    // Orb B — bottom-right, medium drift
    orb(colorB, 0.75 + 0.07 * math.cos(t * 0.9), 0.7 + 0.08 * math.sin(t * 0.6), 0.50);
    // Orb C — centre, fast drift
    orb(colorC, 0.5 + 0.10 * math.sin(t * 1.1), 0.45 + 0.07 * math.cos(t * 0.8), 0.40);
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.t != t || old.opacity != opacity;
}
