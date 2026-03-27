// lib/core/widgets/app_error_view.dart
//
// RxCam Global Widget System — Full-Screen Error State
// Requirements: 14.2, 14.4, 14.5, 14.6

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Full-screen error state widget.
///
/// Renders a centred error icon, descriptive message, and an optional
/// "Try Again" [AppButton] that calls [onRetry] (Req 14.4).
///
/// ```dart
/// if (hasError) return AppErrorView(
///   message: 'Could not load medications.',
///   onRetry: () => provider.reload(),
/// );
/// ```
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Try Again',
                variant: AppButtonVariant.primary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
