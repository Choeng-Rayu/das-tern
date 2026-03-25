// lib/core/widgets/app_empty_view.dart
//
// RxCam Global Widget System — Full-Screen Empty State
// Requirements: 14.3, 14.5, 14.6

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Full-screen empty state widget.
///
/// Renders a centred icon (defaults to inbox) and a descriptive message.
/// Icon uses the active `textTertiary` colour for a subtle appearance.
///
/// ```dart
/// if (items.isEmpty) return const AppEmptyView(
///   message: 'No medications added yet.',
/// );
/// ```
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
