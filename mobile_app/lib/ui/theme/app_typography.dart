import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // H1 - Section Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h1OnDark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnDark,
  );
  
  // H2 - Card Titles
  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2OnDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
  );
  
  // Body Text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyOnDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textOnDark,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
  );
}
