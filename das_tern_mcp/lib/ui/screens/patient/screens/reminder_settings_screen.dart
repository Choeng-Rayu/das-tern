import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../../providers/reminder_provider.dart';
import '../../../../models/reminder_model/reminder_settings.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = provider.settings ?? ReminderSettings();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Grace period
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grace Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Time before a dose is marked as missed',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [10, 20, 30, 60].map((minutes) {
                          final selected = settings.gracePeriodMinutes == minutes;
                          return ChoiceChip(
                            label: Text('$minutes min'),
                            selected: selected,
                            onSelected: (_) {
                              provider.updateSettings({'gracePeriodMinutes': minutes});
                            },
                            selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Repeat reminders
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Repeat Reminders',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Remind again if dose not taken',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: settings.repeatRemindersEnabled,
                            onChanged: (val) {
                              provider.updateSettings({'repeatRemindersEnabled': val});
                            },
                            activeTrackColor: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                      if (settings.repeatRemindersEnabled) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Repeat interval',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [5, 10, 15].map((minutes) {
                            final selected = settings.repeatIntervalMinutes == minutes;
                            return ChoiceChip(
                              label: Text('$minutes min'),
                              selected: selected,
                              onSelected: (_) {
                                provider.updateSettings({'repeatIntervalMinutes': minutes});
                              },
                              selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Per-medication settings
              if (settings.medicationSettings.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Medication Reminders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...settings.medicationSettings.map((med) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      med.medicationName.isNotEmpty ? med.medicationName : 'Medication',
                      style: const TextStyle(fontSize: 15),
                    ),
                    subtitle: med.customTimes != null
                        ? Text(
                            med.customTimes!.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(', '),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          )
                        : null,
                    value: med.remindersEnabled,
                    onChanged: (val) {
                      provider.toggleMedicationReminders(med.medicationId, val);
                    },
                    activeTrackColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}
