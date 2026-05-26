import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Mirrors the prescription lifecycle states in the README and v2 specs.
enum PrescriptionLifecycle { draft, active, paused, inactive }

/// Small status pill rendered next to a prescription title.
///
/// Spec ref: README §"Prescription Lifecycle",
/// 09-design-system-localization §Requirement 3 (`LifecycleBadge`).
class LifecycleBadge extends StatelessWidget {
  const LifecycleBadge({super.key, required this.state});

  final PrescriptionLifecycle state;

  ({Color color, String label}) _spec() => switch (state) {
    PrescriptionLifecycle.draft => (color: Colors.grey, label: 'Draft'),
    PrescriptionLifecycle.active => (color: AppColors.success, label: 'Active'),
    PrescriptionLifecycle.paused => (color: AppColors.warning, label: 'Paused'),
    PrescriptionLifecycle.inactive => (
      color: AppColors.danger,
      label: 'Stopped',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final spec = _spec();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.12),
        borderRadius: AppRadii.allSmall,
      ),
      child: Text(
        spec.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: spec.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
