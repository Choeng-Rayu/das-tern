import 'package:flutter/widgets.dart';

/// Material 3 layout breakpoints.
///
/// Use [Breakpoint.of] in widgets to branch layout. The
/// `AdaptiveScaffold` reusable widget already uses these.
///
/// Spec ref: 09-design-system-localization §Requirement 9.
enum Breakpoint {
  compact, // < 600dp  (phones)
  medium, // 600–839dp (large phones, small tablets)
  expanded; // ≥ 840dp  (tablets, desktops, foldables open)

  /// Resolves the active breakpoint from the nearest [MediaQuery] width.
  static Breakpoint of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 600) return Breakpoint.compact;
    if (width < 840) return Breakpoint.medium;
    return Breakpoint.expanded;
  }

  bool get isCompact => this == Breakpoint.compact;
  bool get isMedium => this == Breakpoint.medium;
  bool get isExpanded => this == Breakpoint.expanded;
  bool get isAtLeastMedium => this != Breakpoint.compact;
}
