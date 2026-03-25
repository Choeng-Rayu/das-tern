// lib/core/widgets/app_text_field.dart
//
// RxCam Global Widget System — Glass Input Field
// iOS 26 Liquid Glass aesthetic — bilingual label, backdrop blur
//
// Requirements: 10.1–10.12

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Glass input field that adapts to light and dark mode.
///
/// - Label is **always rendered as uppercase** above the field (Req 10.4).
/// - Applies `BackdropFilter` blur at 16 dp (Req 10.1).
/// - Focused border uses [AppColors.primary], error border uses [AppColors.danger].
/// - Minimum input area height 44 dp via `contentPadding` (Req 10.11).
///
/// ```dart
/// AppTextField(
///   label: 'Email Address',
///   hint: 'you@example.com',
///   keyboardType: TextInputType.emailAddress,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onChanged,
  });

  /// Field label — rendered uppercase above the input (Req 10.4)
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;

  /// Leading widget inside the field (e.g. an icon)
  final Widget? prefix;

  /// Trailing widget inside the field (e.g. clear button)
  final Widget? suffix;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Uppercase label above field (Req 10.4)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmallResolved(context),
          ),
        ),

        // BackdropFilter + TextFormField
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd), // Req 10.12
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Req 10.1
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: obscureText ? 1 : maxLines,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary, // Req 10.8 / 10.9
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.glassWhite, // Req 10.2 / 10.3
                hintText: hint,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textTertiary,
                ),
                prefixIcon: prefix,
                suffixIcon: suffix,
                // Min height 44 dp (Req 10.11)
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12, // 12×2 + ~20 text = 44 dp
                ),
                // Enabled border (Req 10.5 / 10.6)
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: colors.glassBorder,
                    width: 0.8,
                  ),
                ),
                // Focused border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                // Error border (Req 10.7)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.danger,
                    width: 1.0,
                  ),
                ),
                // Focused error border
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.danger,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
