import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums_model/medication_type.dart';
import '../../../providers/prescription_provider.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/input_widget.dart';

class CreateMedicationScreen extends StatefulWidget {
  const CreateMedicationScreen({super.key});

  @override
  State<CreateMedicationScreen> createState() => _CreateMedicationScreenState();
}

class _CreateMedicationScreenState extends State<CreateMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedForm = 'Tablet';
  MedicationType _selectedType = MedicationType.regular;
  int _frequency = 1;
  final List<TimeOfDay> _reminderTimes = [];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _reminderTimes.add(time);
      });
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reminderTime),
        ),
      );
      return;
    }

    // TODO: Convert to prescription format
    /*
    final medication = Medication(
      name: _nameController.text,
      dosage: _dosageController.text,
      form: _selectedForm,
      instructions: _instructionsController.text.isEmpty 
          ? null 
          : _instructionsController.text,
      type: _selectedType,
      status: MedicationStatus.draft,
      frequency: _frequency,
      reminderTimes: _reminderTimes
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    */

    try {
      // TODO: Implement prescription creation
      /*
      await context.read<PrescriptionProvider>().createPrescription(
        // TODO: Convert to prescription format
        null as dynamic,
      );
      */
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.medicationCreated),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createMedication),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: l10n.medicationName,
              controller: _nameController,
              validator: (value) => 
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: l10n.dosage,
              controller: _dosageController,
              hintText: '500mg',
              validator: (value) => 
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedForm,
              decoration: InputDecoration(
                labelText: l10n.form,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [l10n.tablet, l10n.capsule, l10n.liquid]
                  .map((form) => DropdownMenuItem(
                        value: form,
                        child: Text(form),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedForm = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicationType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: MedicationType.regular,
                  child: Text(l10n.regular),
                ),
                DropdownMenuItem(
                  value: MedicationType.prn,
                  child: Text(l10n.prn),
                ),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: l10n.frequency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: List.generate(4, (i) => i + 1)
                  .map((freq) => DropdownMenuItem(
                        value: freq,
                        child: Text('$freq ${l10n.timesPerDay}'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: l10n.instructions,
              controller: _instructionsController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.reminderTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _addReminderTime,
                  icon: const Icon(Icons.add_alarm),
                ),
              ],
            ),
            ..._reminderTimes.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(time.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeReminderTime(index),
                ),
              );
            }),
            const SizedBox(height: 24),
            CustomButton(
              text: l10n.save,
              onPressed: _saveMedication,
              isLoading: provider.isLoading,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: l10n.cancel,
              onPressed: () => Navigator.pop(context),
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }
}
