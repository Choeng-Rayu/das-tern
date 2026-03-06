import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../models/reminder_model/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onMarkTaken,
    this.onSnooze,
    this.onSkip,
  });

  Color _periodColor() {
    switch (reminder.timePeriod) {
      case 'MORNING':
        return AppColors.morningYellow;
      case 'DAYTIME':
        return AppColors.afternoonOrange;
      case 'NIGHT':
        return AppColors.nightPurple;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _periodIcon() {
    switch (reminder.timePeriod) {
      case 'MORNING':
        return Icons.wb_sunny;
      case 'DAYTIME':
        return Icons.light_mode;
      case 'NIGHT':
        return Icons.nightlight_round;
      default:
        return Icons.schedule;
    }
  }

  String _statusLabel() {
    switch (reminder.status) {
      case 'PENDING':
        return 'Upcoming';
      case 'DELIVERED':
        return 'Due Now';
      case 'SNOOZED':
        return 'Snoozed';
      case 'COMPLETED':
        return 'Taken';
      case 'MISSED':
        return 'Missed';
      default:
        return reminder.status;
    }
  }

  Color _statusColor() {
    switch (reminder.status) {
      case 'PENDING':
        return AppColors.primaryBlue;
      case 'DELIVERED':
        return AppColors.warningOrange;
      case 'SNOOZED':
        return AppColors.neutralGray;
      case 'COMPLETED':
        return AppColors.successGreen;
      case 'MISSED':
        return AppColors.alertRed;
      default:
        return AppColors.neutralGray;
    }
  }

  bool get _isActionable =>
      reminder.status == 'DELIVERED' || reminder.status == 'SNOOZED';

  @override
  Widget build(BuildContext context) {
    final periodColor = _periodColor();
    final timeStr = TimeOfDay.fromDateTime(reminder.scheduledTime).format(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left color strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: periodColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: time + status badge
                    Row(
                      children: [
                        Icon(_periodIcon(), size: 18, color: periodColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: periodColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor().withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Medication name
                    Text(
                      reminder.medicationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (reminder.dosage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reminder.dosage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    // Snooze info
                    if (reminder.status == 'SNOOZED' && reminder.snoozedUntil != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Snoozed until ${TimeOfDay.fromDateTime(reminder.snoozedUntil!).format(context)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutralGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    // Action buttons
                    if (_isActionable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onMarkTaken,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Take'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (reminder.snoozeCount < 3) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onSnooze,
                                icon: const Icon(Icons.snooze, size: 16),
                                label: const Text('Snooze'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onSkip,
                              icon: const Icon(Icons.skip_next, size: 16),
                              label: const Text('Skip'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.neutralGray,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
