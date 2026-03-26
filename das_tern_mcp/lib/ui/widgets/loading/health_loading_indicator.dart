import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Available animation variants for the health loading indicator.
enum HealthLoadingVariant {
  /// Heartbeat pulse animation with ECG-style wave.
  heartbeat,

  /// Rotating pills orbiting around a center point.
  pills,

  /// Medical cross with pulsing glow effect.
  medicalCross,

  /// Circular progress ring with healthcare icon.
  progressRing,
}

/// Display size for the loading indicator.
enum HealthLoadingSize {
  small(32.0),
  medium(64.0),
  large(96.0),
  xlarge(128.0);

  final double value;
  const HealthLoadingSize(this.value);
}

/// A reusable, health-themed loading indicator widget for the DasTern app.
///
/// Features:
/// - Multiple animation variants (heartbeat, pills, medical cross, progress ring)
/// - Customizable size, color, and message
/// - Smooth animations that reflect medical/health theme
/// - Optional loading message/text support
/// - Supports light and dark themes
/// - Premium, trustworthy design suitable for healthcare
///
/// Usage:
/// ```dart
/// // Simple usage with defaults
/// HealthLoadingIndicator()
///
/// // Custom variant and size
/// HealthLoadingIndicator(
///   variant: HealthLoadingVariant.pills,
///   size: HealthLoadingSize.large,
///   message: 'Loading medications...',
/// )
///
/// // Fullscreen overlay
/// HealthLoadingIndicator.fullscreen(
///   message: 'Processing...',
/// )
/// ```
class HealthLoadingIndicator extends StatefulWidget {
  /// The animation variant to display.
  final HealthLoadingVariant variant;

  /// The size of the loading indicator.
  final HealthLoadingSize size;

  /// Primary color for the loading animation.
  final Color? color;

  /// Optional message to display below the indicator.
  final String? message;

  /// Text style for the message.
  final TextStyle? messageStyle;

  /// Whether to show as a fullscreen overlay with barrier.
  final bool isFullscreen;

  /// Background color for fullscreen overlay (only used when isFullscreen=true).
  final Color? overlayColor;

  const HealthLoadingIndicator({
    super.key,
    this.variant = HealthLoadingVariant.heartbeat,
    this.size = HealthLoadingSize.medium,
    this.color,
    this.message,
    this.messageStyle,
    this.isFullscreen = false,
    this.overlayColor,
  });

  /// Creates a fullscreen loading overlay with a semi-transparent barrier.
  const HealthLoadingIndicator.fullscreen({
    super.key,
    this.variant = HealthLoadingVariant.heartbeat,
    this.size = HealthLoadingSize.large,
    this.color,
    this.message,
    this.messageStyle,
    this.overlayColor,
  }) : isFullscreen = true;

  /// Creates a small inline loading indicator without message.
  const HealthLoadingIndicator.inline({
    super.key,
    this.variant = HealthLoadingVariant.progressRing,
    this.size = HealthLoadingSize.small,
    this.color,
  }) : message = null,
       messageStyle = null,
       isFullscreen = false,
       overlayColor = null;

  @override
  State<HealthLoadingIndicator> createState() => _HealthLoadingIndicatorState();
}

class _HealthLoadingIndicatorState extends State<HealthLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _getDuration())
      ..repeat();
  }

  Duration _getDuration() {
    switch (widget.variant) {
      case HealthLoadingVariant.heartbeat:
        return const Duration(milliseconds: 1200);
      case HealthLoadingVariant.pills:
        return const Duration(milliseconds: 2000);
      case HealthLoadingVariant.medicalCross:
        return const Duration(milliseconds: 1500);
      case HealthLoadingVariant.progressRing:
        return const Duration(milliseconds: 1800);
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        widget.color ??
        (isDarkMode ? AppColors.darkPrimary : AppColors.primaryBlue);

    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SizedBox(
              width: widget.size.value,
              height: widget.size.value,
              child: CustomPaint(painter: _getPainter(primaryColor)),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.message!,
            style:
                widget.messageStyle ??
                AppTypography.body.copyWith(
                  color: isDarkMode
                      ? AppColors.textOnDark
                      : AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.isFullscreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color:
            widget.overlayColor ??
            (isDarkMode
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.8)),
        child: Center(child: indicator),
      );
    }

    return indicator;
  }

  CustomPainter _getPainter(Color color) {
    switch (widget.variant) {
      case HealthLoadingVariant.heartbeat:
        return _HeartbeatPainter(animation: _controller, color: color);
      case HealthLoadingVariant.pills:
        return _PillsPainter(animation: _controller, color: color);
      case HealthLoadingVariant.medicalCross:
        return _MedicalCrossPainter(animation: _controller, color: color);
      case HealthLoadingVariant.progressRing:
        return _ProgressRingPainter(animation: _controller, color: color);
    }
  }
}

/// Paints a heartbeat pulse animation with ECG-style wave.
class _HeartbeatPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _HeartbeatPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = animation.value;

    // Pulse effect: expand/contract with heartbeat rhythm
    // Two beats per cycle (0-0.3 first beat, 0.4-0.6 second beat)
    double scale = 1.0;
    if (t < 0.15) {
      scale = 1.0 + (t / 0.15) * 0.25;
    } else if (t < 0.3) {
      scale = 1.25 - ((t - 0.15) / 0.15) * 0.25;
    } else if (t < 0.45) {
      scale = 1.0 + ((t - 0.3) / 0.15) * 0.2;
    } else if (t < 0.6) {
      scale = 1.2 - ((t - 0.45) / 0.15) * 0.2;
    }

    // Draw pulsing glow rings
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final ringT = (t + i * 0.15) % 1.0;
      final radius = size.width * 0.15 * (1 + ringT * 2);
      final opacity = (1 - ringT) * 0.4;

      glowPaint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Draw ECG wave
    final ecgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width * 0.7;
    final h = size.height * 0.3;
    final startX = size.width * 0.15;
    final startY = size.height * 0.5;

    path.moveTo(startX, startY);
    path.lineTo(startX + w * 0.2, startY);
    path.lineTo(startX + w * 0.3, startY - h * 0.6 * scale);
    path.lineTo(startX + w * 0.4, startY + h * 0.4 * scale);
    path.lineTo(startX + w * 0.5, startY - h * 0.8 * scale);
    path.lineTo(startX + w * 0.6, startY + h * 0.3 * scale);
    path.lineTo(startX + w * 0.7, startY);
    path.lineTo(startX + w, startY);

    canvas.drawPath(path, ecgPaint);

    // Draw heart icon in center
    final heartPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final heartPath = _createHeartPath(center, size.width * 0.12 * scale);
    canvas.drawPath(heartPath, heartPaint);
  }

  Path _createHeartPath(Offset center, double size) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;

    path.moveTo(x, y + size * 0.3);
    path.cubicTo(
      x - size * 0.5,
      y - size * 0.3,
      x - size,
      y - size * 0.1,
      x - size,
      y + size * 0.3,
    );
    path.cubicTo(x - size, y + size * 0.7, x, y + size, x, y + size);
    path.cubicTo(
      x,
      y + size,
      x + size,
      y + size * 0.7,
      x + size,
      y + size * 0.3,
    );
    path.cubicTo(
      x + size,
      y - size * 0.1,
      x + size * 0.5,
      y - size * 0.3,
      x,
      y + size * 0.3,
    );
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_HeartbeatPainter oldDelegate) => false;
}

/// Paints rotating pills orbiting around a center point.
class _PillsPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _PillsPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = animation.value;
    final angle = t * 2 * pi;

    // Draw orbiting pills
    final pillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final orbitRadius = size.width * 0.3;

    for (int i = 0; i < 3; i++) {
      final pillAngle = angle + (i * 2 * pi / 3);
      final pillX = center.dx + cos(pillAngle) * orbitRadius;
      final pillY = center.dy + sin(pillAngle) * orbitRadius;

      // Pill rotation
      canvas.save();
      canvas.translate(pillX, pillY);
      canvas.rotate(pillAngle + pi / 2);

      // Draw pill capsule
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.15,
          height: size.width * 0.08,
        ),
        Radius.circular(size.width * 0.04),
      );

      // Alternate colors for variety
      final pillColor = i == 0
          ? color
          : i == 1
          ? AppColors.successGreen
          : AppColors.warningOrange;
      pillPaint.color = pillColor.withValues(alpha: 0.8);

      canvas.drawRRect(pillRect, pillPaint);

      // Divider line
      final dividerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(0, -size.width * 0.04),
        Offset(0, size.width * 0.04),
        dividerPaint,
      );

      canvas.restore();
    }

    // Draw center medical icon
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final crossSize = size.width * 0.08;
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_PillsPainter oldDelegate) => false;
}

/// Paints a medical cross with pulsing glow effect.
class _MedicalCrossPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _MedicalCrossPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = animation.value;

    // Pulsing scale
    final scale = 1.0 + sin(t * 2 * pi) * 0.15;

    // Draw multiple glow layers
    for (int i = 0; i < 5; i++) {
      final glowScale = scale + (i * 0.1);
      final opacity = (1 - i * 0.15) * 0.3;

      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + i * 2.0);

      _drawCross(canvas, center, size.width * 0.35 * glowScale, glowPaint);
    }

    // Draw solid cross
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _drawCross(canvas, center, size.width * 0.35 * scale, crossPaint);

    // Draw particle shimmer effect
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (t * 2 * pi) + (i * pi / 4);
      final distance = size.width * 0.38;
      final particleX = center.dx + cos(angle) * distance;
      final particleY = center.dy + sin(angle) * distance;
      final particleSize = 2.0 + sin(t * 2 * pi + i) * 1.5;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        shimmerPaint,
      );
    }
  }

  void _drawCross(Canvas canvas, Offset center, double size, Paint paint) {
    final barWidth = size * 0.3;

    // Vertical bar
    final vertRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: barWidth, height: size),
      Radius.circular(barWidth / 2),
    );
    canvas.drawRRect(vertRect, paint);

    // Horizontal bar
    final horizRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: barWidth),
      Radius.circular(barWidth / 2),
    );
    canvas.drawRRect(horizRect, paint);
  }

  @override
  bool shouldRepaint(_MedicalCrossPainter oldDelegate) => false;
}

/// Paints a circular progress ring with healthcare icon.
class _ProgressRingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _ProgressRingPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final t = animation.value;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * pi * t;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progressAngle,
      false,
      progressPaint,
    );

    // Draw gradient trail
    for (int i = 0; i < 3; i++) {
      final trailAngle = progressAngle - (i * 0.15);
      final trailOpacity = (1 - i * 0.3) * 0.5;

      final trailPaint = Paint()
        ..color = color.withValues(alpha: trailOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + trailAngle - 0.1,
        0.1,
        false,
        trailPaint,
      );
    }

    // Draw medical bag icon in center
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final iconSize = size.width * 0.2;

    // Bag body
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + iconSize * 0.1),
        width: iconSize,
        height: iconSize * 0.8,
      ),
      Radius.circular(iconSize * 0.1),
    );
    canvas.drawRRect(bagRect, iconPaint);

    // Bag handle
    final handlePath = Path();
    handlePath.moveTo(center.dx - iconSize * 0.3, center.dy - iconSize * 0.25);
    handlePath.quadraticBezierTo(
      center.dx,
      center.dy - iconSize * 0.45,
      center.dx + iconSize * 0.3,
      center.dy - iconSize * 0.25,
    );
    canvas.drawPath(handlePath, iconPaint);

    // Medical cross on bag
    final crossSize = iconSize * 0.25;
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + iconSize * 0.1 - crossSize / 2),
      Offset(center.dx, center.dy + iconSize * 0.1 + crossSize / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - crossSize / 2, center.dy + iconSize * 0.1),
      Offset(center.dx + crossSize / 2, center.dy + iconSize * 0.1),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) => false;
}
