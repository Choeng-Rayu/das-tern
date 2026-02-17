import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/prescription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/medicine_form_widget.dart';

class OcrPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> extractedData;

  const OcrPreviewScreen({super.key, required this.extractedData});

  @override
  State<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends State<OcrPreviewScreen> {
  late List<Map<String, dynamic>> _medicines;
  int? _expandedIndex;
  bool _isSubmitting = false;

  /// Metadata extracted from OCR for the prescription
  String _title = '';
  String? _doctorName;
  String? _diagnosis;

  @override
  void initState() {
    super.initState();
    _parseOcrResponse();
  }

  /// Parse the nested OCR service response into flat medicine maps
  /// that MedicineFormWidget understands.
  ///
  /// OCR response structure:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "prescription": {
  ///       "clinical_information": { "diagnoses": [...] },
  ///       "prescriber": { "name": { "full_name": "..." } },
  ///       "medications": { "items": [...] },
  ///       "prescription_details": { "dates": { "issue_date": { "value": "..." } } }
  ///     }
  ///   },
  ///   "extraction_summary": { ... }
  /// }
  void _parseOcrResponse() {
    final raw = widget.extractedData;

    // Navigate into the nested structure
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final prescription = data['prescription'] as Map<String, dynamic>? ?? {};

    // Extract metadata for the prescription title
    final clinicalInfo =
        prescription['clinical_information'] as Map<String, dynamic>? ?? {};
    final diagnosesList = clinicalInfo['diagnoses'] as List<dynamic>? ?? [];
    final diagnosisStrings = diagnosesList
        .map((d) {
          if (d is Map) {
            final diag = d['diagnosis'] as Map<String, dynamic>? ?? {};
            return (diag['english'] as String?) ??
                (diag['khmer'] as String?) ??
                '';
          }
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
    _diagnosis =
        diagnosisStrings.isNotEmpty ? diagnosisStrings.join(', ') : null;
    _title = _diagnosis ?? 'Scanned Prescription';

    // Extract doctor name
    final prescriber =
        prescription['prescriber'] as Map<String, dynamic>? ?? {};
    final prescriberName =
        prescriber['name'] as Map<String, dynamic>? ?? {};
    _doctorName = prescriberName['full_name'] as String?;

    // Extract medications from the nested items array
    final medications =
        prescription['medications'] as Map<String, dynamic>? ?? {};
    final items = medications['items'] as List<dynamic>? ?? [];

    _medicines = items.map((item) => _mapOcrItemToFormData(item)).toList();
  }

  /// Transform a single OCR medication item into the flat Map format
  /// that MedicineFormWidget expects (medicineName, dosageAmount, frequency, etc.)
  Map<String, dynamic> _mapOcrItemToFormData(dynamic item) {
    if (item is! Map) return {'medicineName': '', 'frequency': ''};
    final med = item['medication'] as Map<String, dynamic>? ?? {};
    final dosing = item['dosing'] as Map<String, dynamic>? ?? {};
    final instructions = item['instructions'] as Map<String, dynamic>? ?? {};

    // Medicine name
    final nameInfo = med['name'] as Map<String, dynamic>? ?? {};
    final medicineName = (nameInfo['brand_name'] as String?) ??
        (nameInfo['full_text'] as String?) ??
        '';
    final medicineNameKhmer = nameInfo['local_name'] as String? ?? '';

    // Strength / dosage
    final strength = med['strength'] as Map<String, dynamic>? ?? {};
    final dosageAmount = (strength['numeric'] is num)
        ? (strength['numeric'] as num).toDouble()
        : 1.0;
    final dosageUnit = (strength['unit'] as String?) ?? 'tablet';

    // Form and type
    final formInfo = med['form'] as Map<String, dynamic>? ?? {};
    final form = (formInfo['value'] as String?) ?? 'tablet';

    // Medicine type from route
    final routeInfo = med['route'] as Map<String, dynamic>? ?? {};
    final routeValue = (routeInfo['value'] as String?) ?? '';
    String medicineType = 'ORAL';
    if (routeValue.toUpperCase() == 'IV' ||
        routeValue.toUpperCase() == 'IM' ||
        routeValue.toUpperCase() == 'SC') {
      medicineType = 'INJECTION';
    } else if (routeValue.toUpperCase() == 'TOPICAL') {
      medicineType = 'TOPICAL';
    }

    // Unit mapping from form
    String unit = 'TABLET';
    final formLower = form.toLowerCase();
    if (formLower == 'capsule') {
      unit = 'CAPSULE';
    } else if (['syrup', 'suspension', 'drops'].contains(formLower)) {
      unit = 'ML';
    }

    // Duration
    final duration = dosing['duration'] as Map<String, dynamic>? ?? {};
    final durationDays = duration['value'] as int?;

    // Schedule (morning, midday, afternoon, evening → morning, daytime, night)
    final schedule = dosing['schedule'] as Map<String, dynamic>? ?? {};
    final freq = schedule['frequency'] as Map<String, dynamic>? ?? {};
    final timesPerDay = freq['times_per_day'] as int? ?? 1;
    final frequency =
        (freq['text_description'] as String?) ?? '$timesPerDay times daily';

    // Parse time slots into morning/daytime/night booleans
    bool morning = false;
    bool daytime = false;
    bool night = false;
    final timeSlots = schedule['time_slots'] as List<dynamic>? ?? [];
    for (final slot in timeSlots) {
      if (slot is! Map) continue;
      final enabled = slot['enabled'] as bool? ?? false;
      if (!enabled) continue;
      final period = slot['period'] as String? ?? '';
      switch (period) {
        case 'morning':
          morning = true;
          break;
        case 'midday':
        case 'afternoon':
          daytime = true;
          break;
        case 'evening':
        case 'night':
          night = true;
          break;
      }
    }

    // Before meal
    final timingWithFood =
        instructions['timing_with_food'] as Map<String, dynamic>? ?? {};
    final beforeMeal = timingWithFood['before_meal'] as bool? ?? false;

    // PRN
    final prnInstructions =
        schedule['prn_instructions'] as Map<String, dynamic>? ?? {};
    final isPRN = prnInstructions['as_needed'] as bool? ?? false;

    // Description
    final clinicalNotes =
        item['clinical_notes'] as Map<String, dynamic>? ?? {};
    final description = clinicalNotes['therapeutic_class'] as String?;

    return {
      'medicineName': medicineName,
      'medicineNameKhmer': medicineNameKhmer,
      'medicineType': medicineType,
      'unit': unit,
      'dosageAmount': dosageAmount,
      'dosageUnit': dosageUnit,
      'form': form,
      'frequency': frequency,
      'durationDays': durationDays ?? 30,
      'morning': morning,
      'daytime': daytime,
      'night': night,
      'beforeMeal': beforeMeal,
      'isPRN': isPRN,
      if (description != null) 'description': description, // ignore: use_null_aware_elements
    };
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneMedicine)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Build medicines array matching PatientMedicationDto
    final medicines = _medicines.asMap().entries.map((e) {
      final med = e.value;

      // Build scheduleTimes from morning/daytime/night booleans
      final scheduleTimes = <Map<String, String>>[];
      if (med['morning'] == true) {
        scheduleTimes.add({'timePeriod': 'morning', 'time': '07:00'});
      }
      if (med['daytime'] == true) {
        scheduleTimes.add({'timePeriod': 'daytime', 'time': '12:00'});
      }
      if (med['night'] == true) {
        scheduleTimes.add({'timePeriod': 'evening', 'time': '20:00'});
      }

      return <String, dynamic>{
        'medicineName': med['medicineName'] ?? '',
        if ((med['medicineNameKhmer'] ?? '').toString().isNotEmpty)
          'medicineNameKhmer': med['medicineNameKhmer'],
        if (med['medicineType'] != null) 'medicineType': med['medicineType'],
        if (med['unit'] != null) 'unit': med['unit'],
        'dosageAmount':
            (med['dosageAmount'] is num) ? med['dosageAmount'] : 1.0,
        'dosageUnit': (med['dosageUnit'] as String?) ??
            (med['unit'] as String? ?? 'tablet').toLowerCase(),
        'form': (med['form'] as String?) ?? 'tablet',
        'frequency': med['frequency'] ?? '1 time daily',
        if (med['durationDays'] != null) 'durationDays': med['durationDays'],
        if (scheduleTimes.isNotEmpty) 'scheduleTimes': scheduleTimes,
        if (med['beforeMeal'] == true) 'beforeMeal': true,
        if (med['isPRN'] == true) 'isPRN': true,
        if ((med['description'] ?? '').toString().isNotEmpty)
          'description': med['description'],
        if ((med['additionalNote'] ?? '').toString().isNotEmpty)
          'additionalNote': med['additionalNote'],
      };
    }).toList();

    // Build CreatePatientPrescriptionDto payload
    final data = <String, dynamic>{
      'title': _title,
      'startDate': DateTime.now().toIso8601String().split('T')[0],
      'medicines': medicines,
      if (_doctorName != null && _doctorName!.isNotEmpty)
        'doctorName': _doctorName,
      if (_diagnosis != null && _diagnosis!.isNotEmpty)
        'diagnosis': _diagnosis,
      'notes': 'OCR scanned prescription',
    };

    final success = await context
        .read<PrescriptionProvider>()
        .createPatientPrescription(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.medicineAddedSuccessfully),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Pop back to the scan tab (2 levels: preview → scan)
        Navigator.of(context)
          ..pop()
          ..pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ocrPreviewTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description
            Card(
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.ocrPreviewDescription,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Extracted medications header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.extractedMedications,
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

            if (_medicines.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 48, color: AppColors.warningOrange),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.noMedicationsExtracted,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ..._medicines.asMap().entries.map((entry) {
                final idx = entry.key;
                final med = entry.value;
                final isExpanded = _expandedIndex == idx;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          [
                            if (med['frequency'] != null) med['frequency'],
                            if (med['durationDays'] != null)
                              '${med['durationDays']}d',
                          ].join(' - '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.edit_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                _expandedIndex = isExpanded ? null : idx;
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
                                if (_expandedIndex == idx) {
                                  _expandedIndex = null;
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
                                _expandedIndex = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: AppSpacing.sm),

            // Add new medicine button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _medicines.add({
                    'medicineName': '',
                    'frequency': '',
                    'durationDays': 30,
                  });
                  _expandedIndex = _medicines.length - 1;
                });
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addRow),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirm button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isSubmitting || provider.isLoading) ? null : _submit,
                icon: _isSubmitting || provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.confirmAndSave),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
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
