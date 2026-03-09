import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/prescription_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/medicine_form_widget.dart';

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

  // ── Full OCR data fields ──
  String? _patientId;
  String? _patientFullName;
  String? _patientKhmerName;
  int? _patientAge;
  String? _patientGender;

  String? _prescriberName;

  String? _facilityNameEnglish;
  String? _facilityNameKhmer;
  String? _facilityType;

  String? _prescriptionType;
  double? _confidenceScore;
  String? _ocrEngine;
  double? _processingTimeMs;
  String? _primaryLanguage;
  List<String> _secondaryLanguages = [];
  String? _validationStatus;
  bool _needsReview = false;
  List<String> _enginesUsed = [];

  @override
  void initState() {
    super.initState();
    _parseOcrResponse();
  }

  /// Parse the nested OCR service response into flat medicine maps
  /// that MedicineFormWidget understands, and extract all prescription metadata.
  ///
  /// OCR response structure:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "prescription": {
  ///       "metadata": { "extraction_info": {...}, "prescription_type": "...", ... },
  ///       "healthcare_facility": { "name": {...}, "type": "..." },
  ///       "patient": { "identification": {...}, "personal_info": {...} },
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

    // ── Patient Information ──
    final patient = prescription['patient'] as Map<String, dynamic>? ?? {};
    final identification =
        patient['identification'] as Map<String, dynamic>? ?? {};
    final patientIdMap =
        identification['patient_id'] as Map<String, dynamic>? ?? {};
    _patientId = patientIdMap['value'] as String?;

    final personalInfo =
        patient['personal_info'] as Map<String, dynamic>? ?? {};
    final nameInfo = personalInfo['name'] as Map<String, dynamic>? ?? {};
    _patientFullName = nameInfo['full_name'] as String?;
    _patientKhmerName = nameInfo['khmer_name'] as String?;

    final ageInfo = personalInfo['age'] as Map<String, dynamic>? ?? {};
    _patientAge = ageInfo['value'] as int?;

    final genderInfo = personalInfo['gender'] as Map<String, dynamic>? ?? {};
    _patientGender =
        (genderInfo['value'] as String?) ?? (genderInfo['english'] as String?);

    // ── Clinical Information (diagnoses) ──
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
    _diagnosis = diagnosisStrings.isNotEmpty
        ? diagnosisStrings.join(', ')
        : null;
    _title = _diagnosis ?? 'Scanned Prescription';

    // ── Prescriber ──
    final prescriber =
        prescription['prescriber'] as Map<String, dynamic>? ?? {};
    final prescriberNameMap = prescriber['name'] as Map<String, dynamic>? ?? {};
    _prescriberName = prescriberNameMap['full_name'] as String?;
    _doctorName = _prescriberName;

    // ── Healthcare Facility ──
    final facility =
        prescription['healthcare_facility'] as Map<String, dynamic>? ?? {};
    final facilityName = facility['name'] as Map<String, dynamic>? ?? {};
    _facilityNameEnglish = facilityName['english'] as String?;
    _facilityNameKhmer = facilityName['khmer'] as String?;
    _facilityType = facility['type'] as String?;

    // ── Metadata ──
    final metadata = prescription['metadata'] as Map<String, dynamic>? ?? {};
    _prescriptionType = metadata['prescription_type'] as String?;
    _validationStatus = metadata['validation_status'] as String?;

    final extractionInfo =
        metadata['extraction_info'] as Map<String, dynamic>? ?? {};
    _ocrEngine = extractionInfo['ocr_engine'] as String?;
    _confidenceScore = (extractionInfo['confidence_score'] is num)
        ? (extractionInfo['confidence_score'] as num).toDouble()
        : null;
    _processingTimeMs = (extractionInfo['processing_time_ms'] is num)
        ? (extractionInfo['processing_time_ms'] as num).toDouble()
        : null;

    final langInfo =
        metadata['languages_detected'] as Map<String, dynamic>? ?? {};
    _primaryLanguage = langInfo['primary'] as String?;
    final secondaryList = langInfo['secondary'] as List<dynamic>? ?? [];
    _secondaryLanguages = secondaryList.map((l) => l.toString()).toList();

    // ── Extraction Summary ──
    final extractionSummary =
        raw['extraction_summary'] as Map<String, dynamic>? ?? {};
    _needsReview = extractionSummary['needs_review'] as bool? ?? false;
    final enginesUsedList =
        extractionSummary['engines_used'] as List<dynamic>? ?? [];
    _enginesUsed = enginesUsedList.map((e) => e.toString()).toList();

    // If confidence not in extraction_info, try extraction_summary
    _confidenceScore ??= (extractionSummary['confidence_score'] is num)
        ? (extractionSummary['confidence_score'] as num).toDouble()
        : null;

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
    final medicineName =
        (nameInfo['brand_name'] as String?) ??
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
    final clinicalNotes = item['clinical_notes'] as Map<String, dynamic>? ?? {};
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
      if (description != null)
        'description': description, // ignore: use_null_aware_elements
    };
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneMedicine)));
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
        'dosageAmount': (med['dosageAmount'] is num)
            ? med['dosageAmount']
            : 1.0,
        'dosageUnit':
            (med['dosageUnit'] as String?) ??
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
      if (_diagnosis != null && _diagnosis!.isNotEmpty) 'diagnosis': _diagnosis,
      'notes': 'OCR scanned prescription',
      'ocrMetadata': <String, dynamic>{
        if (_prescriberName != null) 'prescriberName': _prescriberName,
        if (_patientId != null) 'patientOcrId': _patientId,
        if (_patientKhmerName != null) 'patientKhmerName': _patientKhmerName,
        if (_patientFullName != null) 'patientFullName': _patientFullName,
        if (_patientAge != null) 'patientAge': _patientAge,
        if (_patientGender != null) 'patientGender': _patientGender,
        'healthcareFacility': <String, dynamic>{
          if (_facilityNameEnglish != null) 'nameEnglish': _facilityNameEnglish,
          if (_facilityNameKhmer != null) 'nameKhmer': _facilityNameKhmer,
          if (_facilityType != null) 'type': _facilityType,
        },
        if (_prescriptionType != null) 'prescriptionType': _prescriptionType,
        if (_confidenceScore != null) 'confidenceScore': _confidenceScore,
        if (_ocrEngine != null) 'ocrEngine': _ocrEngine,
        if (_processingTimeMs != null) 'processingTimeMs': _processingTimeMs,
        if (_primaryLanguage != null || _secondaryLanguages.isNotEmpty)
          'languagesDetected': <String, dynamic>{
            if (_primaryLanguage != null) 'primary': _primaryLanguage,
            if (_secondaryLanguages.isNotEmpty)
              'secondary': _secondaryLanguages,
          },
        if (_validationStatus != null) 'validationStatus': _validationStatus,
        'needsReview': _needsReview,
        if (_enginesUsed.isNotEmpty) 'enginesUsed': _enginesUsed,
      },
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

  // ── Helper: build confidence color ──
  Color _confidenceColor(double score) {
    if (score >= 0.8) return AppColors.successGreen;
    if (score >= 0.5) return AppColors.warningOrange;
    return AppColors.alertRed;
  }

  // ── Helper: format prescription type ──
  String _formatPrescriptionType(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'outpatient':
        return l10n.ocrOutpatient;
      case 'inpatient':
        return l10n.ocrInpatient;
      default:
        return type;
    }
  }

  // ── Helper: format facility type ──
  String _formatFacilityType(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return l10n.ocrFacilityHospital;
      case 'clinic':
        return l10n.ocrFacilityClinic;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.ocrPreviewTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
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
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addRow),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isSubmitting || provider.isLoading)
                      ? null
                      : _submit,
                  icon: _isSubmitting || provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(l10n.confirmAndSave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryHeader(context, l10n),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildMedicationsSection(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Prescription summary banner ──────────────────────────────────────────

  Widget _buildSummaryHeader(BuildContext context, AppLocalizations l10n) {
    final facilityName = _facilityNameEnglish ?? _facilityNameKhmer ?? '';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, Color(0xFF1A3BA8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: needs-review badge + confidence score
            Row(
              children: [
                if (_needsReview)
                  _buildBadge(
                    l10n.ocrNeedsReviewYes,
                    Icons.warning_amber_rounded,
                    AppColors.warningOrange,
                  ),
                const Spacer(),
                if (_confidenceScore != null)
                  _buildBadge(
                    l10n.ocrConfidencePercent(
                      (_confidenceScore! * 100).toStringAsFixed(0),
                    ),
                    Icons.verified_outlined,
                    _confidenceColor(_confidenceScore!),
                  ),
              ],
            ),
            if (_needsReview || _confidenceScore != null)
              const SizedBox(height: AppSpacing.sm),

            // Facility
            if (facilityName.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (_facilityType != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatFacilityType(_facilityType!, l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Doctor
            if (_prescriberName != null && _prescriberName!.isNotEmpty)
              _buildHeaderRow(
                Icons.medical_services_outlined,
                _prescriberName!,
                secondSuffix: _prescriptionType != null
                    ? _formatPrescriptionType(_prescriptionType!, l10n)
                    : null,
              ),

            // Patient
            if (_patientFullName != null ||
                _patientAge != null ||
                _patientGender != null)
              _buildHeaderRow(
                Icons.person_outline,
                [
                  ?_patientFullName,
                  if (_patientKhmerName != null &&
                      _patientKhmerName!.isNotEmpty)
                    _patientKhmerName!,
                  if (_patientAge != null) '${_patientAge}y',
                  ?_patientGender,
                ].join(' · '),
              ),

            // Diagnosis
            if (_diagnosis != null && _diagnosis!.isNotEmpty)
              _buildHeaderRow(Icons.assignment_outlined, _diagnosis!),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(IconData icon, String text, {String? secondSuffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
                children: secondSuffix != null
                    ? [
                        const TextSpan(
                          text: '  ·  ',
                          style: TextStyle(color: Colors.white38),
                        ),
                        TextSpan(
                          text: secondSuffix,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Medications section ──────────────────────────────────────────────────

  Widget _buildMedicationsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.extractedMedications,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_medicines.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (_medicines.isEmpty)
          _buildEmptyMedications(context, l10n)
        else
          ..._medicines.asMap().entries.map(
            (e) => _buildMedicineCard(context, e.key, e.value, l10n),
          ),
      ],
    );
  }

  Widget _buildEmptyMedications(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 48,
            color: AppColors.warningOrange,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.noMedicationsExtracted,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    int idx,
    Map<String, dynamic> med,
    AppLocalizations l10n,
  ) {
    final isExpanded = _expandedIndex == idx;
    final name = (med['medicineName'] as String? ?? '').trim();
    final nameKhmer = (med['medicineNameKhmer'] as String? ?? '').trim();
    final frequency = med['frequency'] as String? ?? '';
    final durationDays = med['durationDays'] as int?;
    final dosageAmount = med['dosageAmount'];
    final dosageUnit = (med['dosageUnit'] as String? ?? '').trim();
    final morning = med['morning'] == true;
    final daytime = med['daytime'] == true;
    final night = med['night'] == true;
    final beforeMeal = med['beforeMeal'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isExpanded ? AppColors.primaryBlue : AppColors.neutral300,
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Name + chips + schedule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? l10n.medicineName : name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: name.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (nameKhmer.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          nameKhmer,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Info chips
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (dosageAmount != null)
                            _infoChip(
                              '$dosageAmount${dosageUnit.isNotEmpty ? ' $dosageUnit' : ''}',
                              AppColors.primaryBlue,
                            ),
                          if (frequency.isNotEmpty)
                            _infoChip(frequency, AppColors.successGreen),
                          if (durationDays != null)
                            _infoChip(
                              '$durationDays ${l10n.daysUnit}',
                              AppColors.warningOrange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Time-of-day schedule
                      Row(
                        children: [
                          if (morning)
                            _scheduleChip(
                              Icons.wb_sunny_outlined,
                              const Color(0xFFFFB300),
                              l10n.morning,
                            ),
                          if (daytime)
                            _scheduleChip(
                              Icons.wb_twilight,
                              AppColors.afternoonOrange,
                              l10n.afternoon,
                            ),
                          if (night)
                            _scheduleChip(
                              Icons.nightlight_round,
                              AppColors.primaryBlue,
                              l10n.night,
                            ),
                          if (!morning && !daytime && !night)
                            Text(
                              l10n.ocrNotAvailable,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral400,
                              ),
                            ),
                          if (beforeMeal) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.beforeMeal,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit + Delete actions
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.edit_outlined,
                        size: 20,
                        color: isExpanded
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                        () => _expandedIndex = isExpanded ? null : idx,
                      ),
                      tooltip: isExpanded ? 'Collapse' : 'Edit',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.alertRed,
                      ),
                      onPressed: () => setState(() {
                        _medicines.removeAt(idx);
                        if (_expandedIndex == idx) _expandedIndex = null;
                        if (_expandedIndex != null && _expandedIndex! > idx) {
                          _expandedIndex = _expandedIndex! - 1;
                        }
                      }),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inline edit form (expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: MedicineFormWidget(
                initialData: med,
                showSaveButton: true,
                onSave: (updated) => setState(() {
                  _medicines[idx] = updated;
                  _expandedIndex = null;
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _scheduleChip(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
