import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'tokens/radii.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';

/// Builds the [ThemeData] for the requested [Brightness].
///
/// Both themes share the same component shapes, padding, and typography —
/// only the [ColorScheme] flips. Component themes are configured here so
/// callers in feature widgets do not need to override per-instance.
///
/// Spec ref: 09-design-system-localization §Requirement 2.
ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme cs = brightness == Brightness.light
      ? buildLightScheme()
      : buildDarkScheme();
  final TextTheme texts = AppTypography.textTheme(cs);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    fontFamily: AppTypography.primaryFamily,
    fontFamilyFallback: AppTypography.fallback,
    textTheme: texts,
    primaryTextTheme: texts,

    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: texts.titleLarge,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
    ),

    dividerTheme: DividerThemeData(
      color: cs.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
        textStyle: texts.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide(color: cs.outline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
        textStyle: texts.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        textStyle: texts.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: const OutlineInputBorder(
        borderRadius: AppRadii.allMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadii.allMedium,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.allMedium,
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.allMedium,
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      labelStyle: texts.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md - 2,
      ),
    ),

    chipTheme: ChipThemeData(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      labelStyle: texts.labelMedium,
      side: BorderSide(color: cs.outlineVariant),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allLarge),
      titleTextStyle: texts.titleLarge,
      contentTextStyle: texts.bodyMedium,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.topXLarge),
      showDragHandle: true,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allLarge),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.secondaryContainer,
      labelTextStyle: WidgetStatePropertyAll<TextStyle?>(texts.labelMedium),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.inverseSurface,
      contentTextStyle: texts.bodyMedium?.copyWith(color: cs.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: cs.onSurfaceVariant,
      textColor: cs.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
    ),
  );
}

/// Convenience accessor — light theme.
ThemeData lightTheme() => buildAppTheme(Brightness.light);

/// Convenience accessor — dark theme.
ThemeData darkTheme() => buildAppTheme(Brightness.dark);
