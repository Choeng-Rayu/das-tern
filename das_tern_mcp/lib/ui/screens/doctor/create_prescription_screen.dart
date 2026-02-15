import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/prescription_provider.dart';
import '../../../providers/connection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/medicine_form_widget.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  int _step = 0;
  int _selectedPatientIndex = -1;
  final _diagnosisCtrl = TextEditingController();
  final _clinicalNoteCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  DateTime? _followUpDate;
  final List<Map<String, dynamic>> _medicines = [];

  @override
  void initState() {
    super.initState();
    context.read<ConnectionProvider>().fetchConnections();
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _clinicalNoteCtrl.dispose();
    _symptomsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final connProvider = context.read<ConnectionProvider>();
    final patients = _getPatients(connProvider);
    if (_selectedPatientIndex < 0 ||
        _selectedPatientIndex >= patients.length ||
        _medicines.isEmpty) {
      return;
    }

    final patient = patients[_selectedPatientIndex];
    final patientData = patient.recipient ?? patient.initiator;

    final patientName = patientData != null
        ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
            .trim()
        : l10n.unknown;

    final data = <String, dynamic>{
      'patientId': patient.recipientId,
      'patientName': patientName,
      'patientGender': patientData?['gender'] ?? 'OTHER',
      'patientAge': _calculateAge(patientData?['dateOfBirth']),
      'symptoms': _symptomsCtrl.text.trim(),
      'diagnosis': _diagnosisCtrl.text.trim(),
      if (_clinicalNoteCtrl.text.isNotEmpty)
        'clinicalNote': _clinicalNoteCtrl.text.trim(),
      if (_followUpDate != null)
        'followUpDate': _followUpDate!.toIso8601String().split('T')[0],
      'medications': _medicines
          .asMap()
          .entries
          .map((e) => {
                'rowNumber': e.key + 1,
                ...e.value,
              })
          .toList(),
    };

    final success =
        await context.read<PrescriptionProvider>().createPrescription(data);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.prescriptionCreated)),
      );
      Navigator.pop(context);
    }
  }

  List<dynamic> _getPatients(ConnectionProvider connProvider) {
    return connProvider.connections
        .where((c) => c.status.name == 'accepted')
        .toList();
  }

  int _calculateAge(String? dob) {
    if (dob == null) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createPrescription)),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0 && _selectedPatientIndex < 0) return;
          if (_step == 1 &&
              (_diagnosisCtrl.text.isEmpty || _symptomsCtrl.text.isEmpty)) {
            return;
          }
          if (_step == 2 && _medicines.isEmpty) return;
          if (_step < 3) {
            setState(() => _step++);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        steps: [
          Step(
            title: Text(l10n.selectPatient),
            isActive: _step >= 0,
            content: _buildPatientSelection(),
          ),
          Step(
            title: Text(l10n.diagnosis),
            isActive: _step >= 1,
            content: _buildDiagnosis(),
          ),
          Step(
            title: Text(l10n.medicines),
            isActive: _step >= 2,
            content: _buildMedicines(),
          ),
          Step(
            title: Text(l10n.reviewStep),
            isActive: _step >= 3,
            content: _buildReview(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelection() {
    final l10n = AppLocalizations.of(context)!;
    final connProvider = context.watch<ConnectionProvider>();
    final patients = _getPatients(connProvider);

    if (connProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (patients.isEmpty) {
      return Text(l10n.noConnectedPatients);
    }

    return Column(
      children: patients.asMap().entries.map((entry) {
        final idx = entry.key;
        final conn = entry.value;
        final patientData = conn.recipient ?? conn.initiator;
        final name = patientData != null
            ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
                .trim()
            : l10n.unknown;
        final phone = patientData?['phoneNumber'] ?? '';
        final selected = _selectedPatientIndex == idx;

        return ListTile(
          title: Text(name),
          subtitle: Text(phone),
          leading: CircleAvatar(
            backgroundColor:
                selected ? AppColors.primaryBlue : AppColors.neutral300,
            child: Icon(Icons.person,
                color: selected ? Colors.white : AppColors.textSecondary),
          ),
          selected: selected,
          onTap: () => setState(() => _selectedPatientIndex = idx),
        );
      }).toList(),
    );
  }

  Widget _buildDiagnosis() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TextField(
          controller: _symptomsCtrl,
          decoration: InputDecoration(
            labelText: l10n.symptomsRequired,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _diagnosisCtrl,
          decoration: InputDecoration(
            labelText: l10n.diagnosisRequired,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _clinicalNoteCtrl,
          decoration: InputDecoration(
            labelText: l10n.clinicalNote,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_followUpDate != null
              ? l10n.followUpDateValue('${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}')
              : l10n.setFollowUpDate),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setState(() => _followUpDate = d);
          },
        ),
      ],
    );
  }

  Widget _buildMedicines() {
    return Column(
      children: [
        if (_medicines.isNotEmpty) ...[
          ..._medicines.asMap().entries.map((e) => Card(
                child: ListTile(
                  title: Text(e.value['medicineName'] ?? ''),
                  subtitle: Text(
                      '${e.value['frequency'] ?? ''} - ${e.value['durationDays'] ?? 30} days'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.alertRed),
                    onPressed: () =>
                        setState(() => _medicines.removeAt(e.key)),
                  ),
                ),
              )),
          const Divider(),
        ],
        MedicineFormWidget(
          onSave: (data) => setState(() => _medicines.add(data)),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context)!;
    final connProvider = context.read<ConnectionProvider>();
    final patients = _getPatients(connProvider);
    String patientName = '-';
    if (_selectedPatientIndex >= 0 && _selectedPatientIndex < patients.length) {
      final conn = patients[_selectedPatientIndex];
      final patientData = conn.recipient ?? conn.initiator;
      patientName = patientData != null
          ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
              .trim()
          : '-';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.patient}: $patientName',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${l10n.diagnosis}: ${_diagnosisCtrl.text}'),
        Text('${l10n.symptomsLabel}: ${_symptomsCtrl.text}'),
        Text('${l10n.medicines}: ${_medicines.length}'),
        const SizedBox(height: AppSpacing.md),
        ..._medicines.map((m) => Text('  - ${m['medicineName']}')),
      ],
    );
  }
}
