import 'package:flutter/material.dart';
import '../../models/medication_model/medication.dart';
import '../../models/dose_event_model/dose_event.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final DoseEvent? doseEvent;
  final VoidCallback onTap;
  final VoidCallback? onStatusToggle;

  const MedicationCard({
    super.key,
    required this.medication,
    this.doseEvent,
    required this.onTap,
    this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = doseEvent?.status == 'TAKEN_ON_TIME' || doseEvent?.status == 'TAKEN_LATE';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.medication,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          medication.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${medication.dosage} • ${medication.form}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onStatusToggle != null)
              Checkbox(
                value: isDone,
                onChanged: (_) => onStatusToggle?.call(),
              ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
