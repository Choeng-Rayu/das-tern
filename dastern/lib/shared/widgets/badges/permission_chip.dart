import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';

/// Mirrors the patient-controlled permission levels for connected
/// Doctors / peer-Patients defined in the README and addendum.
enum ConnectionPermission { notAllowed, request, selected, allowed }

/// Small chip indicating the current permission level for a connection.
///
/// Spec ref: README §"Permission Levels",
/// 09-design-system-localization §Requirement 3 (`PermissionChip`).
class PermissionChip extends StatelessWidget {
  const PermissionChip({super.key, required this.permission});

  final ConnectionPermission permission;

  ({Color color, IconData icon, String label}) _spec() => switch (permission) {
    ConnectionPermission.notAllowed => (
      color: AppColors.danger,
      icon: Icons.block,
      label: 'Not allowed',
    ),
    ConnectionPermission.request => (
      color: AppColors.warning,
      icon: Icons.help_outline,
      label: 'Request',
    ),
    ConnectionPermission.selected => (
      color: AppColors.info,
      icon: Icons.check_box_outline_blank,
      label: 'Selected',
    ),
    ConnectionPermission.allowed => (
      color: AppColors.success,
      icon: Icons.check,
      label: 'Allowed',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    return Chip(
      avatar: Icon(spec.icon, size: 16, color: spec.color),
      label: Text(spec.label),
      labelStyle: TextStyle(color: spec.color, fontWeight: FontWeight.w600),
      backgroundColor: spec.color.withValues(alpha: 0.10),
      side: BorderSide(color: spec.color.withValues(alpha: 0.3)),
    );
  }
}
