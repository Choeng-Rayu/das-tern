import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/prescription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/medicine_form_widget.dart';

class CreatePatientMedicineScreen extends StatefulWidget {
  const CreatePatientMedicineScreen({super.key});

  @override
  State<CreatePatientMedicineScreen> createState() =>
      _CreatePatientMedicineScreenState();
}

class _CreatePatientMedicineScreenState
    extends State<CreatePatientMedicineScreen> {
  final _titleController = TextEditingController();
  final List<Map<String, dynamic>> _medicines = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneMedicine)),
      );
      return;
    }

    final data = <String, dynamic>{
      'symptoms': _titleController.text.isNotEmpty
          ? _titleController.text.trim()
          : l10n.selfPrescribed,
      'medications': _medicines
          .asMap()
          .entries
          .map((e) => {
                'rowNumber': e.key + 1,
                ...e.value,
              })
          .toList(),
    };

    final success = await context
        .read<PrescriptionProvider>()
        .createPatientPrescription(data);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicineAddedSuccessfully)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMedicine)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.labelPurpose,
                hintText: l10n.labelPurposeHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_medicines.isNotEmpty) ...[
              Text(l10n.addedMedicines,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              ..._medicines.asMap().entries.map((e) => Card(
                    child: ListTile(
                      title: Text(e.value['medicineName'] ?? ''),
                      subtitle: Text(
                          '${e.value['frequency'] ?? ''} - ${e.value['durationDays'] ?? 30} days'),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete, color: AppColors.alertRed),
                        onPressed: () =>
                            setState(() => _medicines.removeAt(e.key)),
                      ),
                    ),
                  )),
              const Divider(height: AppSpacing.lg),
            ],

            Text(l10n.addMedicine,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            MedicineFormWidget(
              onSave: (data) => setState(() => _medicines.add(data)),
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.saveWithCount(_medicines.length)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
