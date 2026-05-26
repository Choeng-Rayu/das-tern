import 'package:flutter/material.dart';

import 'package:das_tern_mcp/core/widgets/app_empty_view.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/data/models/reminder.dart';
import 'package:das_tern_mcp/data/models/schedule_slot.dart';
import 'package:das_tern_mcp/ui/home/home_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Home screen — renders today's reminders and schedule slots.
///
/// All business logic lives in [HomeViewModel]. This widget only reads
/// state and calls ViewModel methods on user interaction.
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Home',
            currentIndex: 0,
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }

        if (vm.hasError) {
          return AppScaffold(
            title: 'Home',
            currentIndex: 0,
            showBottomNav: false,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Something went wrong.',
              onRetry: vm.refresh,
            ),
          );
        }

        return AppScaffold(
          title: 'Home',
          currentIndex: 0,
          showBottomNav: false,
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _GreetingHeader(greeting: vm.greeting),
                const SizedBox(height: AppSpacing.lg),
                if (vm.todayReminders.isEmpty && vm.scheduleSlots.isEmpty)
                  const AppEmptyView(
                    message: 'No medications scheduled for today.',
                    icon: Icons.medication_outlined,
                    subtitle: 'Add a prescription to get started.',
                  )
                else ...[
                  if (vm.todayReminders.isNotEmpty) ...[
                    _SectionTitle(title: "Today's Reminders"),
                    const SizedBox(height: AppSpacing.sm),
                    ...vm.todayReminders.map(
                      (r) => _ReminderTile(reminder: r),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (vm.scheduleSlots.isNotEmpty) ...[
                    _SectionTitle(title: 'Schedule'),
                    const SizedBox(height: AppSpacing.sm),
                    ...vm.scheduleSlots.map(
                      (slot) => _ScheduleSlotCard(slot: slot),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Here's your medication schedule",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: Icon(
          reminder.isTaken ? Icons.check_circle : Icons.alarm,
          color: reminder.isTaken ? AppColors.successGreen : AppColors.primaryBlue,
        ),
        title: Text(reminder.medicationName),
        subtitle: Text(
          '${reminder.dosage} ${reminder.unit}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Text(
          _formatTime(reminder.scheduledTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _ScheduleSlotCard extends StatelessWidget {
  const _ScheduleSlotCard({required this.slot});

  final ScheduleSlot slot;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_periodIcon(slot.period.name), color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  slot.period.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  slot.time,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...slot.medications.map(
              (med) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${med.name} — ${med.dosage} ${med.unit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _periodIcon(String period) {
    switch (period) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_cloudy_outlined;
      case 'night':
        return Icons.nights_stay_outlined;
      default:
        return Icons.access_time;
    }
  }
}
