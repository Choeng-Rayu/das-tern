import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Size variants for [AppBadge].
enum AppBadgeSize { small, medium, large }

/// Design-system coloured badge / chip for displaying status labels.
///
/// Factory constructors provide pre-configured semantic badges:
/// - [AppBadge.active] — green
/// - [AppBadge.paused] — orange
/// - [AppBadge.completed] — blue/primary
///
/// Usage:
/// ```dart
/// AppBadge(label: 'Active', color: AppColors.successGreen)
/// AppBadge.active()
/// AppBadge.paused()
/// AppBadge.completed()
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.size = AppBadgeSize.small,
  });

  /// Pre-configured "Active" badge (green).
  factory AppBadge.active({Key? key, String label = 'Active'}) => AppBadge(
        key: key,
        label: label,
        color: AppColors.successGreen,
      );

  /// Pre-configured "Paused" badge (orange).
  factory AppBadge.paused({Key? key, String label = 'Paused'}) => AppBadge(
        key: key,
        label: label,
        color: AppColors.warningOrange,
      );

  /// Pre-configured "Completed" badge (primary blue).
  factory AppBadge.completed({Key? key, String label = 'Completed'}) =>
      AppBadge(
        key: key,
        label: label,
        color: AppColors.primaryBlue,
      );

  final String label;
  final Color color;
  final AppBadgeSize size;

  double get _fontSize {
    switch (size) {
      case AppBadgeSize.small:
        return 11;
      case AppBadgeSize.medium:
        return 13;
      case AppBadgeSize.large:
        return 15;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppBadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        );
      case AppBadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
      case AppBadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
