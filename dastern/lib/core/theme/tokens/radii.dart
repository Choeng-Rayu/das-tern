import 'package:flutter/widgets.dart';

/// Corner-radius tokens — keep the set small so the visual language stays
/// coherent. Matches the iOS-26-inspired soft surfaces called out in the
/// design spec.
///
/// Spec ref: 09-design-system-localization §Requirement 11.
class AppRadii {
  const AppRadii._();

  static const Radius small = Radius.circular(8);
  static const Radius medium = Radius.circular(12);
  static const Radius large = Radius.circular(16);
  static const Radius xlarge = Radius.circular(24);

  static const BorderRadius allSmall = BorderRadius.all(small);
  static const BorderRadius allMedium = BorderRadius.all(medium);
  static const BorderRadius allLarge = BorderRadius.all(large);
  static const BorderRadius allXLarge = BorderRadius.all(xlarge);

  /// Bottom-sheet handle radius (top-rounded only).
  static const BorderRadius topXLarge = BorderRadius.vertical(top: xlarge);
}
