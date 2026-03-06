import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/reminder_card.dart';
import '../../../widgets/snooze_bottom_sheet.dart';
import '../../../../providers/reminder_provider.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../models/reminder_model/reminder.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadUpcoming();
    });
  }

  Map<String, List<Reminder>> _groupByDate(List<Reminder> reminders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final groups = <String, List<Reminder>>{};
    for (final r in reminders) {
      final date = DateTime(r.scheduledTime.year, r.scheduledTime.month, r.scheduledTime.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == tomorrow) {
        label = 'Tomorrow';
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }
      groups.putIfAbsent(label, () => []).add(r);
    }
    return groups;
  }

  Future<void> _handleSnooze(Reminder reminder) async {
    final duration = await SnoozeBottomSheet.show(
      context,
      currentSnoozeCount: reminder.snoozeCount,
    );
    if (duration != null && mounted) {
      await context.read<ReminderProvider>().snoozeReminder(reminder.id, duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/patient/reminder-settings'),
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.upcomingReminders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.upcomingReminders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadUpcoming(),
              child: ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: AppColors.neutralGray),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No upcoming reminders',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final groups = _groupByDate(provider.upcomingReminders);

          return RefreshIndicator(
            onRefresh: () => provider.loadUpcoming(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
              itemCount: groups.entries.fold<int>(0, (sum, e) => sum + 1 + e.value.length),
              itemBuilder: (context, index) {
                int current = 0;
                for (final entry in groups.entries) {
                  if (index == current) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  current++;
                  if (index < current + entry.value.length) {
                    final reminder = entry.value[index - current];
                    return ReminderCard(
                      reminder: reminder,
                      onMarkTaken: () {
                        context.read<DoseProvider>().markTaken(
                          reminder.medicationId,
                          reminderId: reminder.id,
                        );
                        provider.loadUpcoming();
                      },
                      onSnooze: () => _handleSnooze(reminder),
                      onSkip: () {
                        context.read<DoseProvider>().skipDose(
                          reminder.medicationId,
                          'Skipped from reminder',
                        );
                        provider.loadUpcoming();
                      },
                    );
                  }
                  current += entry.value.length;
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
