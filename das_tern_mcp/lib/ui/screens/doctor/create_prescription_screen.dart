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
  int _selectedPatientIndex = -1;
  final _diagnosisCtrl = TextEditingController();
  final _clinicalNoteCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  DateTime? _followUpDate;
  final List<Map<String, dynamic>> _medicines = [];
  int? _expandedMedicineIndex;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

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
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    final connProvider = context.read<ConnectionProvider>();
    final patients = _getPatients(connProvider);

    if (_selectedPatientIndex < 0 ||
        _selectedPatientIndex >= patients.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectPatient)),
      );
      return;
    }

    if (_diagnosisCtrl.text.trim().isEmpty ||
        _symptomsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diagnosisRequired)),
      );
      return;
    }

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicines)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

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

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.prescriptionCreated),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
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
    final prescriptionProvider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createPrescription)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Patient Selection ──
              _buildPatientDropdown(),
              const SizedBox(height: AppSpacing.lg),

              // ── Clinical Details ──
              _buildClinicalDetails(),
              const SizedBox(height: AppSpacing.lg),

              // ── Medications Table ──
              _buildMedicationsSection(),
              const SizedBox(height: AppSpacing.lg),

              // ── Review Summary ──
              if (_medicines.isNotEmpty) ...[
                _buildReviewSummary(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Submit Button ──
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || prescriptionProvider.isLoading)
                      ? null
                      : _submit,
                  child: _isSubmitting || prescriptionProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.submitPrescription),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final connProvider = context.watch<ConnectionProvider>();
    final patients = _getPatients(connProvider);

    if (connProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (patients.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10n.noConnectedPatients,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedPatientIndex >= 0 ? _selectedPatientIndex : null,
      decoration: InputDecoration(
        labelText: l10n.selectPatient,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person),
      ),
      items: patients.asMap().entries.map((entry) {
        final conn = entry.value;
        final patientData = conn.recipient ?? conn.initiator;
        final name = patientData != null
            ? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
                .trim()
            : l10n.unknown;
        return DropdownMenuItem(
          value: entry.key,
          child: Text(name),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPatientIndex = val);
      },
    );
  }

  Widget _buildClinicalDetails() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diagnosis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                  ? l10n.followUpDateValue(
                      '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}')
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
        ),
      ),
    );
  }

  Widget _buildMedicationsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.medicationTableTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_medicines.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Existing medicines as expandable cards
            ..._medicines.asMap().entries.map((entry) {
              final idx = entry.key;
              final med = entry.value;
              final isExpanded = _expandedMedicineIndex == idx;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                elevation: isExpanded ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isExpanded
                        ? AppColors.primaryBlue
                        : AppColors.neutral300,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
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
                      title: Text(
                        med['medicineName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${med['frequency'] ?? ''} - ${med['durationDays'] ?? 30}d',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                            ),
                            onPressed: () => setState(() {
                              _expandedMedicineIndex =
                                  isExpanded ? null : idx;
                            }),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.alertRed,
                            ),
                            onPressed: () => setState(() {
                              _medicines.removeAt(idx);
                              if (_expandedMedicineIndex == idx) {
                                _expandedMedicineIndex = null;
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: MedicineFormWidget(
                          initialData: med,
                          showSaveButton: true,
                          onSave: (updatedData) {
                            setState(() {
                              _medicines[idx] = updatedData;
                              _expandedMedicineIndex = null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              );
            }),

            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Add new medicine form
            Text(
              l10n.addRow,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            MedicineFormWidget(
              onSave: (data) => setState(() {
                _medicines.add(data);
                _expandedMedicineIndex = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSummary() {
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

    return Card(
      color: AppColors.primaryBlue.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.prescriptionSummary,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            _summaryRow(l10n.patient, patientName),
            _summaryRow(l10n.diagnosis, _diagnosisCtrl.text),
            _summaryRow(l10n.symptomsLabel, _symptomsCtrl.text),
            _summaryRow(l10n.medicines, '${_medicines.length}'),
            const Divider(),
            ..._medicines.map((m) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    '- ${m['medicineName']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
