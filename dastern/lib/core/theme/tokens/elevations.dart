import 'package:flutter/widgets.dart';

/// Elevation (shadow) tokens for Material surfaces.
///
/// Das Tern leans on soft, low-contrast shadows (the iOS-26 look) so values
/// stay small. The "level" naming mirrors Material 3 elevation tokens.
///
/// Spec ref: 09-design-system-localization §Requirement 11.
class AppElevations {
  const AppElevations._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;

  /// Soft shadow used on elevated cards. Pair with `level1` elevation.
  static const List<BoxShadow> softCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Bottom-bar shadow used on glass surfaces.
  static const List<BoxShadow> bottomBarShadow = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, -2)),
  ];
}
