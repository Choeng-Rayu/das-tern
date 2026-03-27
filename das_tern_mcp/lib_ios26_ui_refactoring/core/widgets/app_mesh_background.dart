// lib/core/widgets/app_mesh_background.dart
//
// RxCam Global Widget System — Animated Mesh Background
// iOS 26 Liquid Glass aesthetic — three animated radial-gradient orbs
//
// Requirements: 5.1–5.6

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated three-orb radial-gradient background rendered behind all screen
/// content. Used by [AppScaffold] to make every screen feel alive.
///
/// Uses two [AnimationController] instances (9 s and 13 s) with
/// `repeat(reverse: true)` to gently animate the orbs.
///
/// **Disposal (Req 5.5):** Both controllers are disposed when this widget
/// is removed from the tree — no memory leaks.
class AppMeshBackground extends StatefulWidget {
  const AppMeshBackground({super.key, required this.child});

  /// Widget rendered above all orb layers.
  final Widget child;

  @override
  State<AppMeshBackground> createState() => _AppMeshBackgroundState();
}

class _AppMeshBackgroundState extends State<AppMeshBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  late final Animation<double> _anim1;
  late final Animation<double> _anim2;
  late final Animation<double> _anim3; // reuses _controller1

  @override
  void initState() {
    super.initState();

    // Orb 1 & 3 controller — 9 s (Req 5.4)
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    // Orb 2 controller — 13 s (Req 5.4)
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: true);

    _anim1 = _controller1;
    _anim2 = _controller2;

    // Third orb reuses controller1 with a different tween range (Req spec)
    _anim3 = Tween<double>(begin: 0.3, end: 0.7).animate(_controller1);
  }

  @override
  void dispose() {
    // Both controllers disposed exactly once (Req 5.5)
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base fill — meshDeep (dark) or lightBackground (light) (Req 5.1, 5.2)
        ColoredBox(color: colors.background),

        // Orb 1 — AppColors.primary, centre (0.2w, 0.3h)
        AnimatedBuilder(
          animation: _anim1,
          builder: (context, child) => CustomPaint(
            painter: _OrbPainter(
              color: AppColors.primary,
              // dark: 0.30 / light: 0.12 (Req 5.2, 5.3)
              opacity: isDark ? 0.30 : 0.12,
              progress: _anim1.value,
              normalizedCenter: const Offset(0.2, 0.3),
            ),
          ),
        ),

        // Orb 2 — AppColors.primaryDark, centre (0.8w, 0.6h)
        AnimatedBuilder(
          animation: _anim2,
          builder: (context, child) => CustomPaint(
            painter: _OrbPainter(
              color: AppColors.primaryDark,
              opacity: isDark ? 0.22 : 0.08,
              progress: _anim2.value,
              normalizedCenter: const Offset(0.8, 0.6),
            ),
          ),
        ),

        // Orb 3 — AppColors.primaryLight, centre (0.5w, 0.8h), reuses ctrl1
        AnimatedBuilder(
          animation: _anim3,
          builder: (context, child) => CustomPaint(
            painter: _OrbPainter(
              color: AppColors.primaryLight,
              opacity: isDark ? 0.16 : 0.06,
              progress: _anim3.value,
              normalizedCenter: const Offset(0.5, 0.8),
            ),
          ),
        ),

        // Child content above all orb layers (Req 5.6)
        widget.child,
      ],
    );
  }
}

/// Paints a single radial-gradient orb whose centre drifts ±10% of the
/// canvas dimensions over the animation cycle.
class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.color,
    required this.opacity,
    required this.progress,
    required this.normalizedCenter,
  });

  final Color color;
  final double opacity;

  /// Animation progress in [0.0, 1.0].
  final double progress;

  /// Base centre as fraction of canvas size (e.g. Offset(0.2, 0.3)).
  final Offset normalizedCenter;

  @override
  void paint(Canvas canvas, Size size) {
    // Drift ±10% of screen dimensions (design spec)
    const drift = 0.10;
    final driftX = (progress - 0.5) * 2 * drift * size.width;
    final driftY = (progress - 0.5) * 2 * drift * size.height;

    final center = Offset(
      normalizedCenter.dx * size.width + driftX,
      normalizedCenter.dy * size.height + driftY,
    );

    final radius = size.width * 0.55;

    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.progress != progress || old.color != color || old.opacity != opacity;
}
