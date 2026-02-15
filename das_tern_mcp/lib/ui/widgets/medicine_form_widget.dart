import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums_model/medication_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MedicineFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;
  final bool showSaveButton;

  const MedicineFormWidget({
    super.key,
    required this.onSave,
    this.initialData,
    this.showSaveButton = true,
  });

  @override
  State<MedicineFormWidget> createState() => _MedicineFormWidgetState();
}

class _MedicineFormWidgetState extends State<MedicineFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameKhmerController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  MedicineType _medicineType = MedicineType.oral;
  MedicineUnit _unit = MedicineUnit.tablet;
  bool _morning = true;
  bool _daytime = false;
  bool _night = false;
  bool _beforeMeal = false;
  bool _isPRN = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameController.text = d['medicineName'] ?? '';
      _nameKhmerController.text = d['medicineNameKhmer'] ?? '';
      _dosageController.text = (d['dosageAmount'] ?? '').toString();
      _frequencyController.text = d['frequency'] ?? '';
      _durationController.text = (d['durationDays'] ?? '').toString();
      _descriptionController.text = d['description'] ?? '';
      _noteController.text = d['additionalNote'] ?? '';
      _medicineType = d['medicineType'] != null
          ? MedicineType.fromJson(d['medicineType'])
          : MedicineType.oral;
      _unit = d['unit'] != null
          ? MedicineUnit.fromJson(d['unit'])
          : MedicineUnit.tablet;
      _morning = d['morning'] ?? true;
      _daytime = d['daytime'] ?? false;
      _night = d['night'] ?? false;
      _beforeMeal = d['beforeMeal'] ?? false;
      _isPRN = d['isPRN'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameKhmerController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'medicineName': _nameController.text.trim(),
      'medicineNameKhmer': _nameKhmerController.text.trim(),
      'medicineType': _medicineType.toJson(),
      'unit': _unit.toJson(),
      'dosageAmount': double.tryParse(_dosageController.text) ?? 1,
      'frequency': _frequencyController.text.trim(),
      'durationDays': int.tryParse(_durationController.text) ?? 30,
      'morning': _morning,
      'daytime': _daytime,
      'night': _night,
      'beforeMeal': _beforeMeal,
      'isPRN': _isPRN,
      if (_descriptionController.text.isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_noteController.text.isNotEmpty)
        'additionalNote': _noteController.text.trim(),
    };

    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.medicineNameRequired,
              hintText: l10n.medicineNameHintExample,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Khmer Name
          TextFormField(
            controller: _nameKhmerController,
            decoration: InputDecoration(
              labelText: l10n.medicineNameKhmer,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Type & Unit row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MedicineType>(
                  initialValue: _medicineType,
                  decoration: InputDecoration(
                    labelText: l10n.typeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: MedicineType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _medicineType = v!),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<MedicineUnit>(
                  initialValue: _unit,
                  decoration: InputDecoration(
                    labelText: l10n.unit,
                    border: const OutlineInputBorder(),
                  ),
                  items: MedicineUnit.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Dosage & Frequency row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: l10n.dosageAmount,
                    hintText: '1',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _frequencyController,
                  decoration: InputDecoration(
                    labelText: l10n.frequencyRequired,
                    hintText: l10n.frequencyHintExample,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Duration
          TextFormField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: l10n.durationDaysLabel,
              hintText: '30',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),

          // Schedule
          Text(l10n.schedule,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _ScheduleChip(
                label: l10n.morning,
                selected: _morning,
                onTap: () => setState(() => _morning = !_morning),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScheduleChip(
                label: l10n.daytime,
                selected: _daytime,
                onTap: () => setState(() => _daytime = !_daytime),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScheduleChip(
                label: l10n.night,
                selected: _night,
                onTap: () => setState(() => _night = !_night),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Switches
          SwitchListTile(
            title: Text(l10n.beforeMeal),
            value: _beforeMeal,
            onChanged: (v) => setState(() => _beforeMeal = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(l10n.prn),
            value: _isPRN,
            onChanged: (v) => setState(() => _isPRN = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionLabel,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Additional Note
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: l10n.additionalNote,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          if (widget.showSaveButton) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text(l10n.saveMedicine),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
