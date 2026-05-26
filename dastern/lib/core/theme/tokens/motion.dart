import 'package:flutter/widgets.dart';

/// Motion tokens — durations + curves used across the app.
///
/// Always honour [MediaQuery.disableAnimations]; use [AppMotion.resolve]
/// to collapse to zero when the OS requests reduced motion.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"Motion tokens".
abstract class AppMotion {
  // Durations
  static const Duration pressDown = Duration(milliseconds: 160);
  static const Duration pressUp = Duration(milliseconds: 200);
  static const Duration tabExpand = Duration(milliseconds: 260);
  static const Duration pageTransition = Duration(milliseconds: 320);
  static const Duration bottomSheet = Duration(milliseconds: 360);
  static const Duration dialog = Duration(milliseconds: 220);
  static const Duration toast = Duration(milliseconds: 280);

  // Curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasisedCurve = Curves.easeInOutCubicEmphasized;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Returns [duration] or [Duration.zero] when the OS requests reduced motion.
  static Duration resolve(BuildContext context, Duration duration) {
    if (MediaQuery.of(context).disableAnimations) return Duration.zero;
    return duration;
  }
}
