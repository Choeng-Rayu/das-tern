import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient selection
  List<Map<String, dynamic>> _connectedPatients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isLoadingPatients = true;
  String? _patientLoadError;

  // Prescription fields
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _clinicalNoteController = TextEditingController();
  DateTime? _followUpDate;
  bool _isUrgent = false;
  final _urgentReasonController = TextEditingController();

  // Patient info (filled from selection or manual)
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  String _patientGender = 'MALE';

  // Medications
  final List<_MedicationEntry> _medications = [];

  // Submission state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addMedication(); // Start with one medication entry
    _loadConnectedPatients();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _clinicalNoteController.dispose();
    _urgentReasonController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    for (final med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConnectedPatients() async {
    try {
      final connections =
          await ApiService.instance.getConnections(status: 'ACCEPTED');
      final profile = await ApiService.instance.getProfile();
      final currentUserId = profile['id'] as String;

      final patients = <Map<String, dynamic>>[];
      for (final conn in connections) {
        final initiator = conn['initiator'] as Map<String, dynamic>?;
        final recipient = conn['recipient'] as Map<String, dynamic>?;

        // The other party (not the doctor) is the patient
        Map<String, dynamic>? patient;
        if (initiator != null && initiator['id'] != currentUserId) {
          if (initiator['role'] == 'PATIENT') patient = initiator;
        }
        if (recipient != null && recipient['id'] != currentUserId) {
          if (recipient['role'] == 'PATIENT') patient = recipient;
        }

        if (patient != null) {
          // Avoid duplicates
          final exists =
              patients.any((p) => p['id'] == patient!['id']);
          if (!exists) {
            patients.add(patient);
          }
        }
      }

      if (mounted) {
        setState(() {
          _connectedPatients = patients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _patientLoadError = e.toString();
          _isLoadingPatients = false;
        });
      }
    }
  }

  void _onPatientSelected(Map<String, dynamic>? patient) {
    setState(() {
      _selectedPatient = patient;
      if (patient != null) {
        final fullName = patient['fullName'] as String? ?? '';
        final firstName = patient['firstName'] as String? ?? '';
        final lastName = patient['lastName'] as String? ?? '';
        _patientNameController.text =
            fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
      }
    });
  }

  void _addMedication() {
    setState(() {
      _medications.add(_MedicationEntry());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one medication is required'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }

    // Validate medications
    for (int i = 0; i < _medications.length; i++) {
      if (_medications[i].nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medication ${i + 1}: Name is required'),
            backgroundColor: AppColors.alertRed,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Build medications list
      final medicationsList = <Map<String, dynamic>>[];
      for (int i = 0; i < _medications.length; i++) {
        final med = _medications[i];
        final medMap = <String, dynamic>{
          'rowNumber': i + 1,
          'medicineName': med.nameController.text.trim(),
        };

        if (med.nameKhmerController.text.trim().isNotEmpty) {
          medMap['medicineNameKhmer'] = med.nameKhmerController.text.trim();
        }

        medMap['medicineType'] = med.medicineType;
        medMap['unit'] = med.unit;

        final dosageAmount =
            double.tryParse(med.dosageAmountController.text) ?? 1;
        medMap['dosageAmount'] = dosageAmount;

        if (med.descriptionController.text.trim().isNotEmpty) {
          medMap['description'] = med.descriptionController.text.trim();
        }

        if (med.frequencyController.text.trim().isNotEmpty) {
          medMap['frequency'] = med.frequencyController.text.trim();
        }

        final durationDays = int.tryParse(med.durationController.text);
        if (durationDays != null) {
          medMap['durationDays'] = durationDays;
        }

        medMap['isPRN'] = med.isPRN;
        medMap['beforeMeal'] = med.beforeMeal;

        // Morning dosage
        if (med.hasMorning) {
          medMap['morningDosage'] = {
            'amount': med.morningAmountController.text.trim().isNotEmpty
                ? med.morningAmountController.text.trim()
                : '1',
            'beforeMeal': med.morningBeforeMeal,
          };
        }

        // Daytime dosage
        if (med.hasDaytime) {
          medMap['daytimeDosage'] = {
            'amount': med.daytimeAmountController.text.trim().isNotEmpty
                ? med.daytimeAmountController.text.trim()
                : '1',
            'beforeMeal': med.daytimeBeforeMeal,
          };
        }

        // Night dosage
        if (med.hasNight) {
          medMap['nightDosage'] = {
            'amount': med.nightAmountController.text.trim().isNotEmpty
                ? med.nightAmountController.text.trim()
                : '1',
            'beforeMeal': med.nightBeforeMeal,
          };
        }

        medicationsList.add(medMap);
      }

      // Build the DTO matching CreatePrescriptionDto
      final dto = <String, dynamic>{
        'patientId': _selectedPatient!['id'],
        'patientName': _patientNameController.text.trim(),
        'patientGender': _patientGender,
        'patientAge': int.tryParse(_patientAgeController.text) ?? 0,
        'symptoms': _symptomsController.text.trim(),
        'medications': medicationsList,
        'isUrgent': _isUrgent,
      };

      if (_diagnosisController.text.trim().isNotEmpty) {
        dto['diagnosis'] = _diagnosisController.text.trim();
      }
      if (_clinicalNoteController.text.trim().isNotEmpty) {
        dto['clinicalNote'] = _clinicalNoteController.text.trim();
      }
      if (_followUpDate != null) {
        dto['followUpDate'] = _followUpDate!.toIso8601String().split('T')[0];
      }
      if (_isUrgent && _urgentReasonController.text.trim().isNotEmpty) {
        dto['urgentReason'] = _urgentReasonController.text.trim();
      }

      await ApiService.instance.createPrescription(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription created successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.message}'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prescription'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Selection Section
                    _buildSectionCard(
                      title: 'Patient Information',
                      icon: Icons.person,
                      children: [
                        _buildPatientSelector(),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _patientNameController,
                          label: 'Patient Name',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown<String>(
                                label: 'Gender',
                                value: _patientGender,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'MALE', child: Text('Male')),
                                  DropdownMenuItem(
                                      value: 'FEMALE', child: Text('Female')),
                                  DropdownMenuItem(
                                      value: 'OTHER', child: Text('Other')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _patientGender = v!),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildTextField(
                                controller: _patientAgeController,
                                label: 'Age',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Clinical Information Section
                    _buildSectionCard(
                      title: 'Clinical Information',
                      icon: Icons.medical_information,
                      children: [
                        _buildTextField(
                          controller: _symptomsController,
                          label: 'Symptoms *',
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          hintText: 'Describe patient symptoms...',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _diagnosisController,
                          label: 'Diagnosis',
                          maxLines: 2,
                          hintText: 'Clinical diagnosis...',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _clinicalNoteController,
                          label: 'Clinical Notes',
                          maxLines: 3,
                          hintText: 'Additional clinical notes...',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Follow-up date
                        InkWell(
                          onTap: _pickFollowUpDate,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Follow-up Date',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: const Icon(Icons.calendar_today,
                                  size: 20),
                            ),
                            child: Text(
                              _followUpDate != null
                                  ? '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}'
                                  : 'Not set',
                              style: TextStyle(
                                color: _followUpDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Urgent toggle
                        SwitchListTile(
                          title: const Text('Urgent Prescription'),
                          subtitle: const Text(
                            'Mark as urgent for immediate attention',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isUrgent,
                          activeThumbColor: AppColors.alertRed,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _isUrgent = v),
                        ),
                        if (_isUrgent) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildTextField(
                            controller: _urgentReasonController,
                            label: 'Urgent Reason',
                            hintText: 'Reason for urgency...',
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Medications Section
                    _buildSectionCard(
                      title: 'Medications',
                      icon: Icons.medication,
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.primaryBlue),
                        onPressed: _addMedication,
                        tooltip: 'Add Medication',
                      ),
                      children: [
                        ..._medications.asMap().entries.map((entry) {
                          return _buildMedicationCard(
                              entry.key, entry.value);
                        }),
                      ],
                    ),

                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),

            // Bottom Submit Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Patient Selector ──────────────────────────────────────────

  Widget _buildPatientSelector() {
    if (_isLoadingPatients) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_patientLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.alertRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.alertRed, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Failed to load patients. $_patientLoadError',
                style: const TextStyle(fontSize: 12, color: AppColors.alertRed),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoadingPatients = true;
                  _patientLoadError = null;
                });
                _loadConnectedPatients();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_connectedPatients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'No connected patients found. Connect with patients first.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: _selectedPatient,
      decoration: InputDecoration(
        labelText: 'Select Patient *',
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      items: _connectedPatients.map((patient) {
        final fullName = patient['fullName'] as String? ?? '';
        final firstName = patient['firstName'] as String? ?? '';
        final lastName = patient['lastName'] as String? ?? '';
        final displayName =
            fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
        final phone = patient['phoneNumber'] as String? ?? '';
        return DropdownMenuItem<Map<String, dynamic>>(
          value: patient,
          child: Text(
            displayName.isNotEmpty
                ? '$displayName${phone.isNotEmpty ? ' ($phone)' : ''}'
                : phone,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onPatientSelected,
      validator: (v) => v == null ? 'Select a patient' : null,
      isExpanded: true,
    );
  }

  // ─── Section Card ──────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  // ─── Medication Card ───────────────────────────────────────────

  Widget _buildMedicationCard(int index, _MedicationEntry med) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.neutralGray.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Medication ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.alertRed, size: 20),
                  onPressed: () => _removeMedication(index),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Medicine name
            _buildTextField(
              controller: med.nameController,
              label: 'Medicine Name *',
              hintText: 'e.g., Amoxicillin',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Khmer name
            _buildTextField(
              controller: med.nameKhmerController,
              label: 'Name (Khmer)',
              hintText: 'Optional Khmer name',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Type and Unit
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Type',
                    value: med.medicineType,
                    items: const [
                      DropdownMenuItem(value: 'ORAL', child: Text('Oral')),
                      DropdownMenuItem(
                          value: 'INJECTION', child: Text('Injection')),
                      DropdownMenuItem(
                          value: 'TOPICAL', child: Text('Topical')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) =>
                        setState(() => med.medicineType = v!),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Unit',
                    value: med.unit,
                    items: const [
                      DropdownMenuItem(
                          value: 'TABLET', child: Text('Tablet')),
                      DropdownMenuItem(
                          value: 'CAPSULE', child: Text('Capsule')),
                      DropdownMenuItem(value: 'ML', child: Text('mL')),
                      DropdownMenuItem(value: 'MG', child: Text('mg')),
                      DropdownMenuItem(value: 'DROP', child: Text('Drop')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => med.unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Dosage amount, duration, frequency
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: med.dosageAmountController,
                    label: 'Dosage Amt',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    hintText: '1',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTextField(
                    controller: med.durationController,
                    label: 'Duration (days)',
                    keyboardType: TextInputType.number,
                    hintText: '7',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildTextField(
              controller: med.frequencyController,
              label: 'Frequency',
              hintText: 'e.g., 3 times/day',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description / Instructions
            _buildTextField(
              controller: med.descriptionController,
              label: 'Instructions',
              maxLines: 2,
              hintText: 'Special instructions...',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Toggles row
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('PRN', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('As needed',
                        style: TextStyle(fontSize: 11)),
                    value: med.isPRN,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (v) =>
                        setState(() => med.isPRN = v ?? false),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Before Meal',
                        style: TextStyle(fontSize: 13)),
                    value: med.beforeMeal,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (v) =>
                        setState(() => med.beforeMeal = v ?? false),
                  ),
                ),
              ],
            ),

            const Divider(),

            // Dosage Schedule
            const Text(
              'Dosage Schedule',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Morning
            _buildDosageRow(
              label: 'Morning',
              icon: Icons.wb_sunny,
              color: AppColors.afternoonOrange,
              isEnabled: med.hasMorning,
              amountController: med.morningAmountController,
              beforeMeal: med.morningBeforeMeal,
              onToggle: (v) =>
                  setState(() => med.hasMorning = v),
              onBeforeMealChanged: (v) =>
                  setState(() => med.morningBeforeMeal = v),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Daytime
            _buildDosageRow(
              label: 'Daytime',
              icon: Icons.wb_cloudy,
              color: AppColors.primaryBlue,
              isEnabled: med.hasDaytime,
              amountController: med.daytimeAmountController,
              beforeMeal: med.daytimeBeforeMeal,
              onToggle: (v) =>
                  setState(() => med.hasDaytime = v),
              onBeforeMealChanged: (v) =>
                  setState(() => med.daytimeBeforeMeal = v),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Night
            _buildDosageRow(
              label: 'Night',
              icon: Icons.nightlight_round,
              color: AppColors.nightPurple,
              isEnabled: med.hasNight,
              amountController: med.nightAmountController,
              beforeMeal: med.nightBeforeMeal,
              onToggle: (v) =>
                  setState(() => med.hasNight = v),
              onBeforeMealChanged: (v) =>
                  setState(() => med.nightBeforeMeal = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageRow({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required TextEditingController amountController,
    required bool beforeMeal,
    required ValueChanged<bool> onToggle,
    required ValueChanged<bool> onBeforeMealChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isEnabled
            ? color.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isEnabled,
              activeColor: color,
              onChanged: (v) => onToggle(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          if (isEnabled) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 60,
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(
                        color: AppColors.neutralGray.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(
                        color: AppColors.neutralGray.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 28,
              child: TextButton(
                onPressed: () => onBeforeMealChanged(!beforeMeal),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: beforeMeal
                      ? color.withValues(alpha: 0.15)
                      : AppColors.neutralGray.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(
                  beforeMeal ? 'Before meal' : 'After meal',
                  style: TextStyle(
                    fontSize: 11,
                    color: beforeMeal ? color : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom Submit Bar ─────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: const BorderSide(color: AppColors.neutralGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitPrescription,
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
                label: Text(
                    _isSubmitting ? 'Creating...' : 'Create Prescription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Medication Entry - holds controllers and state for one medication
// ═══════════════════════════════════════════════════════════════════

class _MedicationEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameKhmerController = TextEditingController();
  final TextEditingController dosageAmountController =
      TextEditingController(text: '1');
  final TextEditingController durationController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Dosage schedule controllers
  final TextEditingController morningAmountController =
      TextEditingController(text: '1');
  final TextEditingController daytimeAmountController =
      TextEditingController(text: '1');
  final TextEditingController nightAmountController =
      TextEditingController(text: '1');

  String medicineType = 'ORAL';
  String unit = 'TABLET';
  bool isPRN = false;
  bool beforeMeal = false;

  // Dosage schedule flags
  bool hasMorning = true;
  bool hasDaytime = false;
  bool hasNight = false;
  bool morningBeforeMeal = false;
  bool daytimeBeforeMeal = false;
  bool nightBeforeMeal = false;

  void dispose() {
    nameController.dispose();
    nameKhmerController.dispose();
    dosageAmountController.dispose();
    durationController.dispose();
    frequencyController.dispose();
    descriptionController.dispose();
    morningAmountController.dispose();
    daytimeAmountController.dispose();
    nightAmountController.dispose();
  }
}
