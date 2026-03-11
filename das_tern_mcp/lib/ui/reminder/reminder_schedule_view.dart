import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/data/models/reminder.dart';
import 'package:das_tern_mcp/data/models/schedule_slot.dart';
import 'package:das_tern_mcp/ui/reminder/reminder_schedule_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class ReminderScheduleView extends StatefulWidget {
  const ReminderScheduleView({super.key, required this.viewModel});
  final ReminderScheduleViewModel viewModel;

  @override
  State<ReminderScheduleView> createState() => _ReminderScheduleViewState();
}

class _ReminderScheduleViewState extends State<ReminderScheduleView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'My Schedule',
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return AppScaffold(
            title: 'My Schedule',
            showBottomNav: false,
            body: AppErrorView(
              message: 'Failed to load schedule.',
              onRetry: vm.loadSchedule,
            ),
          );
        }
        return AppScaffold(
          title: 'My Schedule',
          showBottomNav: false,
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (vm.todayReminders.isNotEmpty) ...[
                _SectionTitle(title: "Today's Reminders"),
                const SizedBox(height: AppSpacing.sm),
                ...vm.todayReminders.map(
                  (r) => _ReminderRow(
                    reminder: r,
                    onMarkTaken: r.isTaken
                        ? null
                        : () => vm.markTaken(r.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (vm.scheduleSlots.isNotEmpty) ...[
                _SectionTitle(title: 'Schedule by Period'),
                const SizedBox(height: AppSpacing.sm),
                ...vm.scheduleSlots.map(
                  (slot) => _SlotSection(slot: slot),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, this.onMarkTaken});
  final Reminder reminder;
  final VoidCallback? onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        child: Row(
          children: [
            Icon(
              reminder.isTaken ? Icons.check_circle : Icons.alarm,
              color: reminder.isTaken
                  ? AppColors.successGreen
                  : AppColors.primaryBlue,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.medicationName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  Text('${reminder.dosage} ${reminder.unit}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!reminder.isTaken)
              AppButton(
                label: 'Taken',
                variant: AppButtonVariant.secondary,
                onPressed: onMarkTaken,
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({required this.slot});
  final ScheduleSlot slot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.period.displayName} — ${slot.time}',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...slot.medications.map(
            (m) => Text('• ${m.name} ${m.dosage} ${m.unit}',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
