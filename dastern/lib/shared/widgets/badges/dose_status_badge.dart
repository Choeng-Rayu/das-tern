import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Mirrors the dose-event statuses in the README and feature specs.
///
/// Kept here (not in `lib/features/reminders/domain/`) because every
/// feature surface needs to render dose status — hoisting it into shared
/// avoids cyclic feature dependencies.
enum DoseStatus { due, takenOnTime, takenLate, missed, skipped }

/// Visual badge for a [DoseStatus].
///
/// Spec ref: README §"DoseEvent Status",
/// 09-design-system-localization §Requirement 3 (`DoseStatusBadge`).
class DoseStatusBadge extends StatelessWidget {
  const DoseStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final DoseStatus status;
  final bool compact;

  ({Color color, IconData icon, String label}) _spec() => switch (status) {
    DoseStatus.due => (
      color: AppColors.info,
      icon: Icons.schedule,
      label: 'Due',
    ),
    DoseStatus.takenOnTime => (
      color: AppColors.success,
      icon: Icons.check_circle,
      label: 'Taken',
    ),
    DoseStatus.takenLate => (
      color: AppColors.warning,
      icon: Icons.check_circle_outline,
      label: 'Late',
    ),
    DoseStatus.missed => (
      color: AppColors.danger,
      icon: Icons.cancel,
      label: 'Missed',
    ),
    DoseStatus.skipped => (
      color: Colors.grey,
      icon: Icons.skip_next,
      label: 'Skipped',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final spec = _spec();

    return Semantics(
      label: 'Dose status: ${spec.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.12),
          borderRadius: AppRadii.allLarge,
          border: Border.all(color: spec.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(spec.icon, size: compact ? 14 : 16, color: spec.color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              spec.label,
              style:
                  (compact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.labelMedium)
                      ?.copyWith(
                        color: spec.color,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
