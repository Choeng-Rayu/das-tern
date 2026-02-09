import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/medication_model/medication.dart';

class MedicationDetailScreen extends StatelessWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${medication.name} ${medication.dosage}',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    l10n.form,
                    medication.form,
                    theme,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    l10n.frequency,
                    '${medication.frequency} ${l10n.timesPerDay}',
                    theme,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Type',
                    medication.type.name,
                    theme,
                  ),
                  if (medication.instructions != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      l10n.instructions,
                      medication.instructions!,
                      theme,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reminderTime,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...medication.reminderTimes.map((time) => ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(time),
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
