import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../domain/medication.dart';
import '../../domain/prescription_enums.dart';
import '../providers/prescription_providers.dart';

class MedicationFormPage extends ConsumerStatefulWidget {
  const MedicationFormPage({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  ConsumerState<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends ConsumerState<MedicationFormPage> {
  final _nameCtrl = TextEditingController();
  final _nameKhCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  MedicineType _type = MedicineType.oral;
  MedicineUnit _unit = MedicineUnit.tablet;
  double _dosage = 1;
  bool _isPrn = false;
  bool _beforeMeal = false;
  bool _morning = false;
  bool _afternoon = false;
  bool _evening = false;
  bool _night = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameKhCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      const slot = DosageSlot(amount: 1, unit: MedicineUnit.tablet);
      final medMap = <String, dynamic>{
        'id': const Uuid().v4(),
        'prescription_id': widget.prescriptionId,
        'row_number': 1,
        'medicine_name': _nameCtrl.text.trim(),
        if (_nameKhCtrl.text.trim().isNotEmpty)
          'medicine_name_khmer': _nameKhCtrl.text.trim(),
        'medicine_type': _type.code,
        'unit': _unit.code,
        'dosage_amount': _dosage,
        'is_prn': _isPrn,
        'before_meal': _beforeMeal,
        if (_morning) 'morning_dosage': slot.toJsonString(),
        if (_afternoon) 'afternoon_dosage': slot.toJsonString(),
        if (_evening) 'evening_dosage': slot.toJsonString(),
        if (_night) 'night_dosage': slot.toJsonString(),
      };
      await ref
          .read(medicationRepositoryProvider)
          .insert(widget.prescriptionId, medMap);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.saveMedicine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          kToolbarHeight + AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _nameCtrl,
                label: 'Medicine name (Latin)',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameKhCtrl,
                label: 'ឈ្មោះថ្នាំ (ខ្មែរ)',
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MedicineType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: MedicineType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.code),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? MedicineType.oral),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MedicineUnit>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: MedicineUnit.values
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.code),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _unit = v ?? MedicineUnit.tablet),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Dosage: ${_dosage.toStringAsFixed(1)}'),
              Slider(
                value: _dosage,
                min: 0.5,
                max: 10,
                divisions: 19,
                label: _dosage.toStringAsFixed(1),
                onChanged: (v) => setState(() => _dosage = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Schedule:'),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  FilterChip(
                    label: const Text('Morning'),
                    selected: _morning,
                    onSelected: (v) => setState(() => _morning = v),
                  ),
                  FilterChip(
                    label: const Text('Afternoon'),
                    selected: _afternoon,
                    onSelected: (v) => setState(() => _afternoon = v),
                  ),
                  FilterChip(
                    label: const Text('Evening'),
                    selected: _evening,
                    onSelected: (v) => setState(() => _evening = v),
                  ),
                  FilterChip(
                    label: const Text('Night'),
                    selected: _night,
                    onSelected: (v) => setState(() => _night = v),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('PRN (as needed)'),
                value: _isPrn,
                onChanged: (v) => setState(() => _isPrn = v),
              ),
              SwitchListTile(
                title: const Text('Before meal'),
                value: _beforeMeal,
                onChanged: (v) => setState(() => _beforeMeal = v),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.save,
                onPressed: _loading ? null : _save,
                loading: _loading,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
