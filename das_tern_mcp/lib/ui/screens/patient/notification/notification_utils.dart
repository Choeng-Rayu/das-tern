import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../ui/theme/app_colors.dart';

/// Shared helpers for the notification feature.

/// Returns a human-readable relative time string, localized via [AppLocalizations].
String timeAgo(DateTime dt, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeAgoJustNow;
  if (diff.inMinutes < 60) return l10n.timeAgoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeAgoHours(diff.inHours);
  return l10n.timeAgoDays(diff.inDays);
}

/// Maps notification type strings to appropriate icons.
IconData iconForNotificationType(String type) {
  switch (type) {
    case 'CONNECTION_REQUEST':
      return Icons.person_add;
    case 'PRESCRIPTION_UPDATE':
      return Icons.medication;
    case 'MISSED_DOSE_ALERT':
      return Icons.warning_amber;
    case 'URGENT_PRESCRIPTION_CHANGE':
      return Icons.priority_high;
    case 'FAMILY_ALERT':
      return Icons.family_restroom;
    case 'VITAL_ANOMALY':
      return Icons.monitor_heart;
    case 'EMERGENCY_ALERT':
      return Icons.emergency;
    default:
      return Icons.notifications;
  }
}

/// A small colored badge showing connection status.
Widget statusBadge({
  required IconData icon,
  required Color color,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

/// Color for connection border based on status.
Color connectionBorderColor({
  required bool isPending,
  required bool isAccepted,
}) {
  if (isPending) return AppColors.primaryBlue.withValues(alpha: 0.3);
  if (isAccepted) return AppColors.successGreen.withValues(alpha: 0.3);
  return AppColors.neutral300;
}
