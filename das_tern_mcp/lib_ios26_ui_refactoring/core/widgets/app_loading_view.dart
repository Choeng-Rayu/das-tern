// lib/core/widgets/app_loading_view.dart
//
// RxCam Global Widget System — Full-Screen Loading State
// Requirements: 14.1, 14.5, 14.6

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Full-screen loading state widget.
///
/// Renders a centred [CircularProgressIndicator] in [AppColors.primary]
/// with an optional message using the active `bodyMedium` text style.
///
/// ```dart
/// if (isLoading) return const AppLoadingView(message: 'Fetching prescriptions…');
/// ```
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
