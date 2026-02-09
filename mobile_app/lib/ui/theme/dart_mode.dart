import 'package:flutter/material.dart';
import 'design_tokens.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF5C7CFF),
    secondary: Color(0xFFFF8A5B),
    surface: Color(0xFF1E1E1E),
    error: Color(0xFFEF5350),
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: AppColors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: AppColors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: AppColors.white,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
    ),
  ),
);
