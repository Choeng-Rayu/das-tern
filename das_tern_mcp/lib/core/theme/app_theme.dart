import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/light_theme.dart';
import 'package:das_tern_mcp/ui/theme/dark_theme.dart';

export 'package:das_tern_mcp/ui/theme/light_theme.dart';
export 'package:das_tern_mcp/ui/theme/dark_theme.dart';

/// Central access point for the app's [ThemeData] objects.
///
/// Delegates to the canonical [lightTheme] and [darkTheme] defined in
/// `lib/ui/theme/`. Widgets that need to resolve the current theme should
/// use [Theme.of(context)] or [AppTheme.of(context)] instead.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppTheme {
  AppTheme._();

  /// Light theme — wraps [lightTheme] from `lib/ui/theme/light_theme.dart`.
  static ThemeData get light => lightTheme;

  /// Dark theme — wraps [darkTheme] from `lib/ui/theme/dark_theme.dart`.
  static ThemeData get dark => darkTheme;

  /// Convenience accessor identical to [Theme.of(context)].
  static ThemeData of(BuildContext context) => Theme.of(context);
}
