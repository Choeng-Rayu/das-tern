import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/batch_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/medicine_form_widget.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _nameCtrl = TextEditingController();
  TimeOfDay? _selectedTime;
  final List<Map<String, dynamic>> _medicines = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.batchName)),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectTime)),
      );
      return;
    }

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneMedicine)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'scheduledTime': _formatTimeOfDay(_selectedTime!),
      'medicines': _medicines,
    };

    final success = await context.read<BatchProvider>().createBatch(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchCreated),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createBatchGroup)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Batch name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.batchName,
                hintText: l10n.batchNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Time picker
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.selectTime,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedTime != null
                      ? l10n.batchScheduledTime(
                          _formatTimeOfDay(_selectedTime!))
                      : l10n.selectTime,
                  style: TextStyle(
                    color: _selectedTime != null
                        ? null
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Added medicines
            if (_medicines.isNotEmpty) ...[
              Text(
                l10n.medicines,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._medicines.asMap().entries.map((e) {
                final idx = e.key;
                final med = e.value;
                return Dismissible(
                  key: ValueKey('med_$idx'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    color: AppColors.alertRed,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) =>
                      setState(() => _medicines.removeAt(idx)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(med['medicineName'] ?? ''),
                      subtitle: Text(
                        '${med['frequency'] ?? ''} - ${med['durationDays'] ?? 30}d',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _medicines.removeAt(idx)),
                      ),
                    ),
                  ),
                );
              }),
              const Divider(height: AppSpacing.lg),
            ],

            // Add medicine form
            Text(
              l10n.addRow,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            MedicineFormWidget(
              onSave: (data) => setState(() => _medicines.add(data)),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.reviewAndSave),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
