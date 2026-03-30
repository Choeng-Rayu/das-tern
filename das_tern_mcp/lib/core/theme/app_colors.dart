import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF009DFF);
  static const Color primaryDark = Color(0xFF0070CC);
  static const Color primaryLight = Color(0xFF66C8FF);

  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF5AC8FA);

  static const Color glassPrimary = Color(0x1A009DFF);
  static const Color glassDanger = Color(0x1AFF3B30);

  static const Color meshDeep = Color(0xFF050A14);
  static const Color meshMid = Color(0xFF0A1628);
  static const Color glassWhiteDark = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x40000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xB3FFFFFF);
  static const Color textTertiaryDark = Color(0x66FFFFFF);

  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color glassWhiteLight = Color(0x99FFFFFF);
  static const Color glassBorderLight = Color(0x1F000000);
  static const Color glassShadowLight = Color(0x1A000000);
  static const Color textPrimaryLight = Color(0xFF0D0D0D);
  static const Color textSecondaryLight = Color(0x993C3C43);
  static const Color textTertiaryLight = Color(0x4D3C3C43);

  static _AppColorScheme of(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const _AppColorScheme.dark()
        : const _AppColorScheme.light();
  }
}

class _AppColorScheme {
  final Color background;
  final Color surface;
  final Color glassWhite;
  final Color glassBorder;
  final Color glassShadowColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const _AppColorScheme.dark()
      : background = AppColors.meshDeep,
        surface = AppColors.meshMid,
        glassWhite = AppColors.glassWhiteDark,
        glassBorder = AppColors.glassBorderDark,
        glassShadowColor = AppColors.glassShadow,
        textPrimary = AppColors.textPrimaryDark,
        textSecondary = AppColors.textSecondaryDark,
        textTertiary = AppColors.textTertiaryDark;

  const _AppColorScheme.light()
      : background = AppColors.lightBackground,
        surface = AppColors.lightSurface,
        glassWhite = AppColors.glassWhiteLight,
        glassBorder = AppColors.glassBorderLight,
        glassShadowColor = AppColors.glassShadowLight,
        textPrimary = AppColors.textPrimaryLight,
        textSecondary = AppColors.textSecondaryLight,
        textTertiary = AppColors.textTertiaryLight;
}
