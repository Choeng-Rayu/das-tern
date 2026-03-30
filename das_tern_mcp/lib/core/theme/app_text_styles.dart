import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle resolve(TextStyle base, BuildContext context) {
    return base.copyWith(color: AppColors.of(context).textPrimary);
  }

  static TextStyle headlineMediumResolved(BuildContext context) {
    return resolve(headlineMedium, context);
  }

  static TextStyle bodyMediumResolved(BuildContext context) {
    return bodyMedium.copyWith(color: AppColors.of(context).textSecondary);
  }

  static TextStyle labelSmallResolved(
    BuildContext context, {
    Color? color,
  }) {
    return labelSmall.copyWith(
      color: color ?? AppColors.of(context).textTertiary,
    );
  }
}
