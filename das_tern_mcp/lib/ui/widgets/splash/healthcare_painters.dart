import 'dart:math';
import 'package:flutter/material.dart';

/// Paints an animated ECG heartbeat line.
class EcgPainter extends CustomPainter {
  final double progress;
  final Color color;

  EcgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.2, mid);
    path.lineTo(w * 0.3, mid - h * 0.35);
    path.lineTo(w * 0.4, mid + h * 0.25);
    path.lineTo(w * 0.5, mid - h * 0.45);
    path.lineTo(w * 0.6, mid + h * 0.15);
    path.lineTo(w * 0.7, mid);
    path.lineTo(w, mid);

    final pathMetrics = path.computeMetrics().first;
    final drawLength = pathMetrics.length * progress.clamp(0.0, 1.0);
    final extractedPath = pathMetrics.extractPath(0, drawLength);

    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(EcgPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Paints a pill capsule icon.
class PillPainter extends CustomPainter {
  final Color color;
  final double opacity;

  PillPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final radius = h * 0.35;

    // Draw pill capsule shape (horizontal)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.8, h * 0.7),
      Radius.circular(radius),
    );
    canvas.drawRRect(rect, paint);

    // Divider in the middle
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(PillPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

/// Paints a medical cross icon.
class MedicalCrossPainter extends CustomPainter {
  final Color color;
  final double opacity;

  MedicalCrossPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final arm = min(w, h) * 0.35;

    // Vertical bar
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), paint);
    // Horizontal bar
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), paint);
  }

  @override
  bool shouldRepaint(MedicalCrossPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

/// Paints a stethoscope icon.
class StethoscopePainter extends CustomPainter {
  final Color color;
  final double opacity;

  StethoscopePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Earpieces (two small arcs at the top)
    final path = Path();
    path.moveTo(w * 0.25, h * 0.1);
    path.quadraticBezierTo(w * 0.25, h * 0.35, w * 0.4, h * 0.4);

    path.moveTo(w * 0.75, h * 0.1);
    path.quadraticBezierTo(w * 0.75, h * 0.35, w * 0.6, h * 0.4);

    // Tube going down
    path.moveTo(w * 0.4, h * 0.4);
    path.quadraticBezierTo(w * 0.5, h * 0.45, w * 0.6, h * 0.4);

    path.moveTo(w * 0.5, h * 0.42);
    path.lineTo(w * 0.5, h * 0.6);

    // Chest piece (circle at the bottom)
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.75), w * 0.15, paint);
  }

  @override
  bool shouldRepaint(StethoscopePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

/// Paints a clock icon.
class ClockPainter extends CustomPainter {
  final Color color;
  final double opacity;

  ClockPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.4;

    // Circle
    canvas.drawCircle(Offset(cx, cy), radius, paint);

    // Hour hand
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - radius * 0.5), paint);

    // Minute hand
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + radius * 0.55, cy + radius * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
