import 'package:flutter/material.dart';

/// Design token colors extracted from Figma and docs.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primaryBlue = Color(0xFF2D5BFF);
  static const Color darkBlue = Color(0xFF1A2744);

  // ── Alert & Status ──
  static const Color alertRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);

  // ── Time Period ──
  static const Color morningYellow = Color(0xFFFFC107);
  static const Color afternoonOrange = Color(0xFFFF6B35);
  static const Color nightPurple = Color(0xFF6B4AA3);

  // ── Neutral ──
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutralGray = Color(0xFF9E9E9E);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Status ──
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFFA726);
  static const Color statusError = Color(0xFFE53935);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A2744);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Dark Theme Variants ──
  static const Color darkPrimary = Color(0xFF5C7CFF);
  static const Color darkSecondary = Color(0xFFFF8A5B);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkError = Color(0xFFEF5350);
}
