import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/data/models/schedule_slot.dart';
import 'package:das_tern/ui/reminder/reminder_schedule_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReminderScheduleView extends StatelessWidget {
  const ReminderScheduleView({super.key});

  String _periodLabel(SchedulePeriod period) {
    switch (period) {
      case SchedulePeriod.morning:
        return 'Morning';
      case SchedulePeriod.afternoon:
        return 'Afternoon';
      case SchedulePeriod.night:
        return 'Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reminder Schedule',
      showBackButton: true,
      body: Consumer<ReminderScheduleViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading schedule...');
          }

          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load.execute,
            );
          }

          return ListView.separated(
            itemCount: viewModel.slots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final slot = viewModel.slots[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_periodLabel(slot.period)),
                    const SizedBox(height: 8),
                    ...slot.reminders.map(
                      (reminder) => Text(
                        '${reminder.medicationName} at ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
