import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class PrescriptionScanScreen extends StatefulWidget {
  const PrescriptionScanScreen({super.key});

  @override
  State<PrescriptionScanScreen> createState() => _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState extends State<PrescriptionScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _scanPrescription() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result =
          await ApiService.instance.extractPrescription(_selectedImage!);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show review/edit dialog with OCR results
        final confirmed = await _showOcrReviewDialog(result);
        if (confirmed == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription saved successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          setState(() {
            _selectedImage = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'OCR extraction failed. Please try again.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showOcrReviewDialog(Map<String, dynamic> ocrResult) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OcrReviewSheet(ocrResult: ocrResult),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.scan,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Use camera to capture prescription'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select JPG, PNG image from device'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview area
            GestureDetector(
              onTap: _isProcessing ? null : _showImageSourcePicker,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.neutralGray.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 64,
                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Tap to select or capture\nprescription image',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Supports JPG, PNG',
                            style: TextStyle(
                              color: AppColors.neutralGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            if (_selectedImage == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            if (_selectedImage != null) ...[
              // Scan button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _scanPrescription,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(_isProcessing ? 'Processing...' : 'Scan Prescription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Change image button
              TextButton.icon(
                onPressed: _isProcessing ? null : _showImageSourcePicker,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Image'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.alertRed, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.alertRed, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Instructions
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for best results:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _TipRow(icon: Icons.wb_sunny, text: 'Ensure good lighting'),
                  _TipRow(icon: Icons.crop_free, text: 'Capture the full prescription'),
                  _TipRow(icon: Icons.blur_off, text: 'Avoid blurry images'),
                  _TipRow(icon: Icons.image, text: 'JPG and PNG formats supported'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OCR Review/Edit Bottom Sheet (Phase 2)
// ═══════════════════════════════════════════════════════════════

class OcrReviewSheet extends StatefulWidget {
  final Map<String, dynamic> ocrResult;

  const OcrReviewSheet({super.key, required this.ocrResult});

  @override
  State<OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends State<OcrReviewSheet> {
  late TextEditingController _titleController;
  late TextEditingController _doctorNameController;
  late TextEditingController _diagnosisController;
  late List<_EditableMedication> _medications;
  bool _isSaving = false;
  double _confidenceScore = 0.0;
  bool _needsReview = false;
  List<String> _fieldsNeedingReview = [];

  @override
  void initState() {
    super.initState();
    _parseOcrResult();
  }

  void _parseOcrResult() {
    final data = widget.ocrResult['data'];
    final prescription = data?['prescription'];
    final summary = widget.ocrResult['extraction_summary'];

    _confidenceScore = (summary?['confidence_score'] ?? 0.0).toDouble();
    _needsReview = summary?['needs_review'] ?? false;
    _fieldsNeedingReview =
        List<String>.from(summary?['fields_needing_review'] ?? []);

    // Parse diagnosis
    final diagnoses = prescription?['clinical_information']?['diagnoses'] as List? ?? [];
    final diagnosisTexts = diagnoses
        .map((d) => d['diagnosis']?['english'] ?? d['diagnosis']?['khmer'] ?? '')
        .where((s) => s.toString().isNotEmpty)
        .toList();
    final diagnosis = diagnosisTexts.join(', ');

    // Parse prescriber
    final doctorName =
        prescription?['prescriber']?['name']?['full_name'] ?? '';

    _titleController = TextEditingController(
        text: diagnosis.isNotEmpty ? diagnosis : 'Scanned Prescription');
    _doctorNameController = TextEditingController(text: doctorName);
    _diagnosisController = TextEditingController(text: diagnosis);

    // Parse medications
    final items = prescription?['medications']?['items'] as List? ?? [];
    _medications = items.map((item) {
      final med = item['medication'];
      final dosing = item['dosing'];
      final instructions = item['instructions'];

      final name =
          med?['name']?['brand_name'] ?? med?['name']?['full_text'] ?? '';
      final localName = med?['name']?['local_name'] ?? '';
      final strength = med?['strength']?['value'] ?? '';
      final form = med?['form']?['value'] ?? 'tablet';
      final durationDays = dosing?['duration']?['value'];
      final timesPerDay =
          dosing?['schedule']?['frequency']?['times_per_day'] ?? 1;
      final beforeMeal =
          instructions?['timing_with_food']?['before_meal'] == true;

      // Parse time slots
      final timeSlots = dosing?['schedule']?['time_slots'] as List? ?? [];
      bool morning = false, midday = false, afternoon = false, evening = false;
      for (final slot in timeSlots) {
        if (slot['enabled'] != true) continue;
        switch (slot['period']) {
          case 'morning':
            morning = true;
            break;
          case 'midday':
            midday = true;
            break;
          case 'afternoon':
            afternoon = true;
            break;
          case 'evening':
          case 'night':
            evening = true;
            break;
        }
      }

      return _EditableMedication(
        nameController: TextEditingController(text: name),
        localNameController: TextEditingController(text: localName),
        strengthController: TextEditingController(text: strength),
        form: form,
        durationDays: durationDays,
        timesPerDay: timesPerDay,
        morning: morning,
        midday: midday,
        afternoon: afternoon,
        evening: evening,
        beforeMeal: beforeMeal,
      );
    }).toList();
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isSaving = true);

    try {
      // Build the CreatePatientPrescriptionDto
      final now = DateTime.now();
      final startDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Calculate end date from max duration
      int maxDuration = 0;
      for (final med in _medications) {
        if (med.durationDays != null && med.durationDays! > maxDuration) {
          maxDuration = med.durationDays!;
        }
      }
      String? endDate;
      if (maxDuration > 0) {
        final end = now.add(Duration(days: maxDuration));
        endDate =
            '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      }

      final medicines = _medications.map((med) {
        final scheduleTimes = <Map<String, String>>[];
        if (med.morning) {
          scheduleTimes.add({'timePeriod': 'morning', 'time': '07:00'});
        }
        if (med.midday) {
          scheduleTimes.add({'timePeriod': 'daytime', 'time': '12:00'});
        }
        if (med.afternoon) {
          scheduleTimes.add({'timePeriod': 'afternoon', 'time': '17:00'});
        }
        if (med.evening) {
          scheduleTimes.add({'timePeriod': 'evening', 'time': '20:00'});
        }

        final count =
            [med.morning, med.midday, med.afternoon, med.evening]
                .where((v) => v)
                .length;

        return {
          'medicineName': med.nameController.text,
          'medicineNameKhmer': med.localNameController.text.isNotEmpty
              ? med.localNameController.text
              : null,
          'medicineType': 'ORAL',
          'unit': 'TABLET',
          'dosageAmount': 1,
          'dosageUnit': med.strengthController.text.isNotEmpty
              ? med.strengthController.text
              : 'tablet',
          'form': med.form,
          'frequency': '${count > 0 ? count : med.timesPerDay}ដង/១ថ្ងៃ',
          if (scheduleTimes.isNotEmpty) 'scheduleTimes': scheduleTimes,
          if (med.durationDays != null) 'durationDays': med.durationDays,
          'beforeMeal': med.beforeMeal,
          'isPRN': false,
        };
      }).toList();

      final dto = {
        'title': _titleController.text,
        if (_doctorNameController.text.isNotEmpty)
          'doctorName': _doctorNameController.text,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (_diagnosisController.text.isNotEmpty)
          'diagnosis': _diagnosisController.text,
        'notes':
            'OCR scanned (confidence: ${(_confidenceScore * 100).toStringAsFixed(0)}%)',
        'medicines': medicines,
      };

      await ApiService.instance.createPatientPrescription(dto);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.message}'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorNameController.dispose();
    _diagnosisController.dispose();
    for (final med in _medications) {
      med.nameController.dispose();
      med.localNameController.dispose();
      med.strengthController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Review Prescription',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),

              // Confidence indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildConfidenceBar(),
              ),

              if (_needsReview && _fieldsNeedingReview.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.afternoonOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: AppColors.afternoonOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppColors.afternoonOrange, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Please review: ${_fieldsNeedingReview.join(", ")}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Divider(),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Title
                    _buildFieldLabel('Prescription Title'),
                    _buildTextField(_titleController),
                    const SizedBox(height: AppSpacing.md),

                    // Doctor Name
                    _buildFieldLabel('Doctor Name'),
                    _buildTextField(_doctorNameController),
                    const SizedBox(height: AppSpacing.md),

                    // Diagnosis
                    _buildFieldLabel('Diagnosis'),
                    _buildTextField(_diagnosisController, maxLines: 2),
                    const SizedBox(height: AppSpacing.lg),

                    // Medications
                    Row(
                      children: [
                        const Text(
                          'Medications',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${_medications.length} found',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    ..._medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      return _buildMedicationCard(index, med);
                    }),

                    const SizedBox(height: 100), // bottom padding for button
                  ],
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                              _isSaving ? null : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            side: const BorderSide(color: AppColors.neutralGray),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _confirmAndSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isSaving
                              ? 'Saving...'
                              : 'Confirm & Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfidenceBar() {
    final percentage = (_confidenceScore * 100).toStringAsFixed(0);
    Color color;
    if (_confidenceScore >= 0.8) {
      color = AppColors.successGreen;
    } else if (_confidenceScore >= 0.6) {
      color = AppColors.afternoonOrange;
    } else {
      color = AppColors.alertRed;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            _confidenceScore >= 0.8
                ? Icons.check_circle
                : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Confidence: $percentage%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            _confidenceScore >= 0.8
                ? 'High accuracy'
                : 'Please verify details',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
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

  Widget _buildMedicationCard(int index, _EditableMedication med) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Medication',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.alertRed, size: 20),
                  onPressed: () {
                    setState(() {
                      med.nameController.dispose();
                      med.localNameController.dispose();
                      med.strengthController.dispose();
                      _medications.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Medicine name
            _buildFieldLabel('Name'),
            _buildTextField(med.nameController),
            const SizedBox(height: AppSpacing.sm),

            // Local name
            _buildFieldLabel('Local Name (Khmer)'),
            _buildTextField(med.localNameController),
            const SizedBox(height: AppSpacing.sm),

            // Strength
            _buildFieldLabel('Strength/Dosage'),
            _buildTextField(med.strengthController),
            const SizedBox(height: AppSpacing.sm),

            // Duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Duration (days)'),
                      TextField(
                        controller: TextEditingController(
                            text: med.durationDays?.toString() ?? ''),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            med.durationDays = int.tryParse(v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Before Meal'),
                      Switch(
                        value: med.beforeMeal,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: (v) =>
                            setState(() => med.beforeMeal = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Schedule
            _buildFieldLabel('Schedule'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _buildScheduleChip('Morning', med.morning,
                    (v) => setState(() => med.morning = v)),
                _buildScheduleChip('Midday', med.midday,
                    (v) => setState(() => med.midday = v)),
                _buildScheduleChip('Afternoon', med.afternoon,
                    (v) => setState(() => med.afternoon = v)),
                _buildScheduleChip('Evening', med.evening,
                    (v) => setState(() => med.evening = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleChip(
      String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class _EditableMedication {
  final TextEditingController nameController;
  final TextEditingController localNameController;
  final TextEditingController strengthController;
  String form;
  int? durationDays;
  int timesPerDay;
  bool morning;
  bool midday;
  bool afternoon;
  bool evening;
  bool beforeMeal;

  _EditableMedication({
    required this.nameController,
    required this.localNameController,
    required this.strengthController,
    required this.form,
    this.durationDays,
    required this.timesPerDay,
    required this.morning,
    required this.midday,
    required this.afternoon,
    required this.evening,
    required this.beforeMeal,
  });
}
