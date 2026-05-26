import 'package:flutter/animation.dart';

/// Motion tokens — durations + curves used across the app.
///
/// Material 3 motion vocabulary: emphasised vs. standard vs. quick.
/// Page transitions use `standard`; in-screen state changes use `quick`;
/// hero / large surface changes use `emphasised`.
///
/// Always honour [MediaQuery.disableAnimations] in widgets that animate;
/// the app sets durations to zero in that case (see `app.dart`).
///
/// Spec ref: 09-design-system-localization §Requirement 10.
class AppMotion {
  const AppMotion._();

  // Durations
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasised = Duration(milliseconds: 320);

  // Curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasisedCurve = Curves.easeInOutCubicEmphasized;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}
