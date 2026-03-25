// lib/core/widgets/app_badge.dart
//
// RxCam Global Widget System — Status Badge
// iOS 26 Liquid Glass aesthetic — five semantic variants
//
// Requirements: 12.1–12.10

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Badge variant enum — five semantic statuses. (Req 12.1)
enum AppBadgeVariant { active, pending, completed, flagged, info }

/// Status pill badge with a semi-transparent coloured background.
///
/// **Label is always uppercase** (Req 12.7) — colour is never the sole
/// status indicator (accessibility, Req 15.7).
///
/// Background is always 15% opacity of the badge colour in both modes (Req 12.8).
///
/// ```dart
/// AppBadge(label: 'Active', variant: AppBadgeVariant.active)
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  final String label;
  final AppBadgeVariant variant;

  /// Maps variant to its semantic badge colour.
  Color _badgeColor() {
    switch (variant) {
      case AppBadgeVariant.active:
        return AppColors.success;   // #34C759 (Req 12.2)
      case AppBadgeVariant.pending:
        return AppColors.warning;   // #FF9500 (Req 12.3)
      case AppBadgeVariant.completed:
        return AppColors.primary;   // #009DFF (Req 12.4)
      case AppBadgeVariant.flagged:
        return AppColors.danger;    // #FF3B30 (Req 12.5)
      case AppBadgeVariant.info:
        return AppColors.info;      // #5AC8FA (Req 12.6)
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();

    return Container(
      constraints: const BoxConstraints(minHeight: 22), // Req 12.10
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, // 8 dp (Req 12.10)
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15), // 15% opacity fill (Req 12.8)
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull), // pill (Req 12.9)
      ),
      child: Text(
        label.toUpperCase(), // always uppercase (Req 12.7)
        style: AppTextStyles.labelSmall.copyWith(color: badgeColor),
      ),
    );
  }
}
