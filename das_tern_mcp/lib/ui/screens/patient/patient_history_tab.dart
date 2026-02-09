import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dose_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// History tab – dose adherence history with date range.
class PatientHistoryTab extends StatefulWidget {
  const PatientHistoryTab({super.key});

  @override
  State<PatientHistoryTab> createState() => _PatientHistoryTabState();
}

class _PatientHistoryTabState extends State<PatientHistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      context.read<DoseProvider>().fetchHistory(
            startDate: weekAgo.toIso8601String().split('T')[0],
            endDate: now.toIso8601String().split('T')[0],
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.neutral300),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No history yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your dose history will appear here.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final dose = provider.history[index];
                    final isTaken = dose.status.contains('TAKEN');
                    return ListTile(
                      leading: Icon(
                        isTaken ? Icons.check_circle : Icons.cancel,
                        color: isTaken
                            ? AppColors.successGreen
                            : AppColors.alertRed,
                      ),
                      title: Text(dose.medicationName),
                      subtitle: Text(
                        '${dose.scheduledTime.hour}:${dose.scheduledTime.minute.toString().padLeft(2, '0')} – ${dose.status}',
                      ),
                      trailing: Text(
                        '${dose.scheduledTime.day}/${dose.scheduledTime.month}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
    );
  }
}
