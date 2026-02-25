import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/batch_model/medication_batch.dart';
import '../../../../providers/batch_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/medicine_form_widget.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  late TextEditingController _nameCtrl;
  TimeOfDay? _selectedTime;
  bool _isEditing = false;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    context.read<BatchProvider>().fetchBatch(widget.batchId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startEditing(MedicationBatch batch) {
    _nameCtrl.text = batch.name;
    final parts = batch.scheduledTime.split(':');
    if (parts.length >= 2) {
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    setState(() => _isEditing = true);
  }

  Future<void> _saveEdit() async {
    final l10n = AppLocalizations.of(context)!;
    final data = <String, dynamic>{};

    final batch = context.read<BatchProvider>().selectedBatch;
    if (batch == null) return;

    if (_nameCtrl.text.trim() != batch.name) {
      data['name'] = _nameCtrl.text.trim();
    }
    if (_selectedTime != null) {
      final newTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      if (newTime != batch.scheduledTime) {
        data['scheduledTime'] = newTime;
      }
    }

    if (data.isEmpty) {
      setState(() => _isEditing = false);
      return;
    }

    final success = await context
        .read<BatchProvider>()
        .updateBatch(widget.batchId, data);

    if (mounted) {
      setState(() => _isEditing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchUpdated),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteBatch() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBatch),
        content: Text(l10n.deleteBatchConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.alertRed)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success =
          await context.read<BatchProvider>().deleteBatch(widget.batchId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.batchDeleted)),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addMedicine(Map<String, dynamic> data) async {
    await context
        .read<BatchProvider>()
        .addMedicineToBatch(widget.batchId, data);
    if (mounted) {
      setState(() => _showAddForm = false);
      context.read<BatchProvider>().fetchBatch(widget.batchId);
    }
  }

  Future<void> _removeMedicine(String medicineId) async {
    await context
        .read<BatchProvider>()
        .removeMedicineFromBatch(widget.batchId, medicineId);
    if (mounted) {
      context.read<BatchProvider>().fetchBatch(widget.batchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<BatchProvider>();
    final batch = provider.selectedBatch;

    return Scaffold(
      appBar: AppBar(
        title: Text(batch?.name ?? l10n.batchGroupsTitle),
        actions: [
          if (batch != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing(batch),
            ),
          if (batch != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
              onPressed: _deleteBatch,
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : batch == null
              ? Center(child: Text(provider.error ?? l10n.unknown))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header info / edit form
                      if (_isEditing) _buildEditForm() else _buildHeader(batch),
                      const SizedBox(height: AppSpacing.lg),

                      // Medications list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.medicines,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAddForm = !_showAddForm),
                            icon: Icon(_showAddForm
                                ? Icons.close
                                : Icons.add),
                            label: Text(_showAddForm
                                ? l10n.cancel
                                : l10n.addRow),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      if (_showAddForm) ...[
                        MedicineFormWidget(onSave: _addMedicine),
                        const Divider(height: AppSpacing.lg),
                      ],

                      if (batch.medications.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              l10n.noMedications,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...batch.medications.map((med) => Card(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: const Icon(Icons.medication,
                                    color: AppColors.primaryBlue),
                                title: Text(med.medicineName),
                                subtitle: Text(
                                  [
                                    if (med.frequency != null) med.frequency!,
                                    if (med.durationDays != null)
                                      '${med.durationDays}d',
                                    if (med.dosageAmount != null)
                                      '${med.dosageAmount} ${med.unit ?? ''}',
                                  ].join(' - '),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.alertRed),
                                  onPressed: med.id != null
                                      ? () => _removeMedicine(med.id!)
                                      : null,
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(MedicationBatch batch) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  batch.isActive
                      ? Icons.check_circle
                      : Icons.pause_circle_outline,
                  color: batch.isActive
                      ? AppColors.successGreen
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  batch.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.batchScheduledTime(batch.scheduledTime)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.batchMedicineCount(batch.medications.length),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.batchName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ??
                      const TimeOfDay(hour: 8, minute: 0),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.selectTime,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : l10n.selectTime,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _saveEdit,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
