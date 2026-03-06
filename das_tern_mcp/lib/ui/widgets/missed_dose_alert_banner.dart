import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../models/reminder_model/reminder.dart';

class MissedDoseAlertBanner extends StatelessWidget {
  final List<Reminder> missedReminders;
  final void Function(Reminder)? onMarkTaken;
  final VoidCallback? onDismiss;

  const MissedDoseAlertBanner({
    super.key,
    required this.missedReminders,
    this.onMarkTaken,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (missedReminders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.alertRed, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${missedReminders.length} Missed Dose${missedReminders.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.alertRed,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, size: 18, color: AppColors.neutralGray),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final reminder in missedReminders.take(3)) ...[
            _MissedDoseItem(
              reminder: reminder,
              onMarkTaken: onMarkTaken != null ? () => onMarkTaken!(reminder) : null,
            ),
            if (reminder != missedReminders.take(3).last)
              const SizedBox(height: AppSpacing.xs),
          ],
          if (missedReminders.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '+${missedReminders.length - 3} more',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissedDoseItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onMarkTaken;

  const _MissedDoseItem({required this.reminder, this.onMarkTaken});

  bool get _canStillMark {
    return DateTime.now().difference(reminder.scheduledTime).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeOfDay.fromDateTime(reminder.scheduledTime).format(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${reminder.medicationName} - $timeStr',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        if (_canStillMark && onMarkTaken != null)
          TextButton(
            onPressed: onMarkTaken,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Mark Taken'),
          ),
      ],
    );
  }
}
