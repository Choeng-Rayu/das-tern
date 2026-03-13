import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ocr_info_section_widget.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PrescriptionProvider>().fetchPrescription(
      widget.prescriptionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();
    final auth = context.watch<AuthProvider>();
    final rx = provider.selectedPrescription;
    final isDoctor = auth.user?['role'] == 'DOCTOR';


    return Scaffold(
      appBar: AppBar(title: Text(l10n.prescriptionDetails)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rx == null
          ? Center(child: Text(l10n.notFound))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Patient info Card
                  Container(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white ,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow:  [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            0.5,
                          ), // Shadow color with opacity
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ]
                    ),
                    child: Column(
                      children: [
                        // avatar card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFFD6E3F8),
                              child: Icon(
                                Icons.person,
                                size: 34,
                                color: AppColors.primaryBlue,
                              ),
                            ),

                            const SizedBox(width: AppSpacing.md),

                            Expanded(
                              child: Text(
                                rx.patientName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  rx.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                rx.status,
                                style: TextStyle(
                                  color: _statusColor(rx.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Patient info
                        _InfoRow(l10n.patient, rx.patientName),
                        if (rx.doctor != null && rx.doctor!['fullName'] != null)
                          _InfoRow(
                            l10n.prescribedBy,
                            rx.doctor!['fullName'] as String,
                          ),
                        _InfoRow(l10n.symptomsLabel, rx.symptoms),
                        if (rx.diagnosis != null)
                          _InfoRow(l10n.diagnosis, rx.diagnosis!),
                        if (rx.clinicalNote != null)
                          _InfoRow(l10n.clinicalNote, rx.clinicalNote!),
                        if (rx.doctorLicenseNumber != null)
                          _InfoRow(l10n.licenseNumber, rx.doctorLicenseNumber!),
                        if (rx.followUpDate != null)
                          _InfoRow(
                            l10n.followUpLabel,
                            '${rx.followUpDate!.day}/${rx.followUpDate!.month}/${rx.followUpDate!.year}',
                          ),
                        

                      ],
                    ),

                  ),
                  
                  // Status badge
                  
                  const SizedBox(height: AppSpacing.md),


                  // OCR Metadata sections
                  if (rx.ocrMetadata != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildOcrScanBanner(l10n),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPrescriberSection(l10n, rx.ocrMetadata!),
                    _buildFacilitySection(l10n, rx.ocrMetadata!),
                    _buildScanMetadataSection(l10n, rx.ocrMetadata!),
                  ],
                  
                  
                  const SizedBox(height: AppSpacing.sm),
                
                  Container(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            0.5,
                          ), // Shadow color with opacity
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.medicines,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'v${rx.currentVersion}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),
                        

                        ...rx.medications.map(
                          (med) => Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.medicineName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (med.medicineNameKhmer.isNotEmpty)
                                    Text(
                                      med.medicineNameKhmer,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text('${l10n.frequency}: ${med.frequency}'),
                                  Text(
                                    '${l10n.timing}: ${med.timing == 'before' ? l10n.beforeMeal : l10n.afterMeal}',
                                  ),
                                  if (med.duration != null)
                                    Text(
                                      '${l10n.durationDays}: ${med.duration} ${l10n.days}',
                                    ),
                                  if (med.description != null)
                                    Text(
                                      '${l10n.descriptionLabel}: ${med.description}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                




                  const SizedBox(height: AppSpacing.lg),

                  // Action buttons
                  if (!isDoctor &&
                      (rx.status == 'PENDING_CONFIRMATION' ||
                          rx.status == 'DRAFT'))
                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            onPressed: () async {
                              final ok = await provider.rejectPrescription(
                                rx.id!,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? l10n.prescriptionRejected
                                          : (provider.error ?? ''),
                                    ),
                                    backgroundColor: ok
                                        ? null
                                        : AppColors.alertRed,
                                  ),
                                );
                                if (ok) Navigator.pop(context);
                              }
                            },
                            child: Text(l10n.rejectPrescription),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
                              await provider.confirmPrescription(rx.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.prescriptionConfirmed),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(l10n.confirm),
                          ),
                        ),
                      ],
                    ),

                  if (!isDoctor && rx.status == 'ACTIVE')
                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            onPressed: () => provider.pausePrescription(rx.id!),
                            child: Text(l10n.pauseButton),
                          ),
                        ),
                      ],
                    ),

                  if (!isDoctor && rx.status == 'PAUSED')
                    Row(
                      children: [
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () =>
                                provider.resumePrescription(rx.id!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(l10n.resumeButton),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  /// Banner indicating this prescription was created from OCR scan.
  Widget _buildOcrScanBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.ocrScanInfoSection,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Prescriber information section from OCR metadata.
  Widget _buildPrescriberSection(
    AppLocalizations l10n,
    Map<String, dynamic> meta,
  ) {
    final prescriberName = meta['prescriberName'] as String? ?? '';
    if (prescriberName.isEmpty) return const SizedBox.shrink();

    return OcrInfoSectionWidget(
      icon: Icons.medical_services_outlined,
      title: l10n.ocrPrescriberSection,
      iconColor: AppColors.primaryBlue,
      entries: [
        OcrInfoEntry(label: l10n.ocrPrescriberName, value: prescriberName),
      ],
    );
  }

  /// Healthcare facility section from OCR metadata.
  Widget _buildFacilitySection(
    AppLocalizations l10n,
    Map<String, dynamic> meta,
  ) {
    final facility = meta['healthcareFacility'] as Map<String, dynamic>?;
    if (facility == null) return const SizedBox.shrink();

    final nameEnglish = facility['nameEnglish'] as String? ?? '';
    final nameKhmer = facility['nameKhmer'] as String? ?? '';
    final facilityType = facility['type'] as String? ?? '';

    String displayType = '';
    if (facilityType == 'hospital') {
      displayType = l10n.ocrFacilityHospital;
    } else if (facilityType == 'clinic') {
      displayType = l10n.ocrFacilityClinic;
    } else if (facilityType.isNotEmpty) {
      displayType = facilityType;
    }

    final displayName = nameEnglish.isNotEmpty ? nameEnglish : nameKhmer;

    if (displayName.isEmpty && displayType.isEmpty) {
      return const SizedBox.shrink();
    }

    return OcrInfoSectionWidget(
      icon: Icons.local_hospital_outlined,
      title: l10n.ocrFacilitySection,
      iconColor: AppColors.successGreen,
      entries: [
        OcrInfoEntry(label: l10n.ocrFacilityName, value: displayName),
        OcrInfoEntry(label: l10n.ocrFacilityType, value: displayType),
      ],
    );
  }

  /// Scan metadata section (confidence, engine, processing time, etc.).
  Widget _buildScanMetadataSection(
    AppLocalizations l10n,
    Map<String, dynamic> meta,
  ) {
    final confidenceScore = meta['confidenceScore'] as num? ?? 0;
    final ocrEngine = meta['ocrEngine'] as String? ?? '';
    final processingTimeMs = meta['processingTimeMs'] as num? ?? 0;
    final prescriptionType = meta['prescriptionType'] as String? ?? '';
    final validationStatus = meta['validationStatus'] as String? ?? '';

    // Languages
    final languagesDetected =
        meta['languagesDetected'] as Map<String, dynamic>?;
    String languagesDisplay = '';
    if (languagesDetected != null) {
      final primary = languagesDetected['primary'] as String? ?? '';
      final secondary = languagesDetected['secondary'] as List<dynamic>? ?? [];
      final parts = <String>[
        if (primary.isNotEmpty) primary,
        ...secondary.map((e) => e.toString()),
      ];
      languagesDisplay = parts.join(', ');
    }

    // Confidence color
    final confidencePercent = (confidenceScore * 100).toStringAsFixed(1);
    Color confidenceColor;
    if (confidenceScore >= 0.8) {
      confidenceColor = AppColors.successGreen;
    } else if (confidenceScore >= 0.5) {
      confidenceColor = AppColors.warningOrange;
    } else {
      confidenceColor = AppColors.alertRed;
    }

    // Prescription type display
    String typeDisplay = '';
    if (prescriptionType == 'outpatient') {
      typeDisplay = l10n.ocrOutpatient;
    } else if (prescriptionType == 'inpatient') {
      typeDisplay = l10n.ocrInpatient;
    } else if (prescriptionType.isNotEmpty) {
      typeDisplay = prescriptionType;
    }

    // Validation status display
    String validationDisplay = '';
    if (validationStatus == 'validated') {
      validationDisplay = l10n.ocrValidated;
    } else if (validationStatus.isNotEmpty) {
      validationDisplay = validationStatus;
    }

    // Confidence badge widget for trailing
    final confidenceBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        l10n.ocrConfidencePercent(confidencePercent),
        style: TextStyle(
          color: confidenceColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );

    return OcrInfoSectionWidget(
      icon: Icons.analytics_outlined,
      title: l10n.ocrMetadataSection,
      iconColor: AppColors.neutralGray,
      initiallyExpanded: false,
      trailing: confidenceBadge,
      entries: [
        OcrInfoEntry(
          label: l10n.ocrConfidenceScore,
          value: l10n.ocrConfidencePercent(confidencePercent),
          valueColor: confidenceColor,
        ),
        OcrInfoEntry(label: l10n.ocrEngine, value: ocrEngine),
        OcrInfoEntry(
          label: l10n.ocrProcessingTime,
          value: processingTimeMs > 0
              ? l10n.ocrMilliseconds(processingTimeMs.toStringAsFixed(0))
              : '',
        ),
        OcrInfoEntry(label: l10n.ocrPrescriptionType, value: typeDisplay),
        OcrInfoEntry(label: l10n.ocrLanguagesDetected, value: languagesDisplay),
        OcrInfoEntry(label: l10n.ocrValidationStatus, value: validationDisplay),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.successGreen;
      case 'PENDING_CONFIRMATION':
      case 'DRAFT':
        return AppColors.warningOrange;
      case 'PAUSED':
        return AppColors.neutralGray;
      case 'REJECTED':
        return AppColors.alertRed;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}
