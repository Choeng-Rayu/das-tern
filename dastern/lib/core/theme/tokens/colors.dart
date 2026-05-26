import 'package:flutter/material.dart';

/// Brand and semantic color tokens for Das Tern.
///
/// The brand seed (`#1A8E5F`) drives the [ColorScheme] in both light and
/// dark themes via Material 3 tonal palettes. Semantic accents are layered
/// on top for status badges, adherence rings, and validation cues — they
/// stay constant across themes because their meaning is fixed.
///
/// Spec ref: 09-design-system-localization §Requirement 1.
class AppColors {
  const AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────
  /// Das Tern green — the brand seed used for `ColorScheme.fromSeed`.
  static const Color brandSeed = Color(0xFF1A8E5F);
  static const Color brandSurface = Color(0xFFE6F4ED);

  // ── Semantic accents ────────────────────────────────────────────────
  static const Color success = Color(0xFF1FAA66);
  static const Color warning = Color(0xFFF1A93A);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF3A7BD6);

  // ── Adherence indicators ────────────────────────────────────────────
  /// ≥90% — on track.
  static const Color adherenceGreen = success;

  /// 70%-89% — needs attention.
  static const Color adherenceYellow = warning;

  /// <70% — at risk.
  static const Color adherenceRed = danger;

  // ── Neutrals (for surfaces/text outside the M3 scheme) ──────────────
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
}

/// Builds the light Material 3 [ColorScheme] from the Das Tern brand seed.
ColorScheme buildLightScheme() => ColorScheme.fromSeed(
  seedColor: AppColors.brandSeed,
  brightness: Brightness.light,
);

/// Builds the dark Material 3 [ColorScheme] from the Das Tern brand seed.
ColorScheme buildDarkScheme() => ColorScheme.fromSeed(
  seedColor: AppColors.brandSeed,
  brightness: Brightness.dark,
);
