import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/patient_report_data.dart';
import '../models/prescription_model/prescription.dart';
import '../models/dose_event_model/dose_event.dart';
import '../models/health_model/health_vital.dart';

/// Service to generate Patient Health Report PDFs
/// Generates professional A4 reports with patient health data
class PatientReportPdfService {
  // A4 dimensions: 595 x 842 points
  static const PdfPageFormat _pageFormat = PdfPageFormat.a4;

  // 2cm margins = 56.69 points
  static const double _margin = 56.69;

  // Color scheme (theme-neutral, professional medical colors)
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1976D2); // Blue
  static const PdfColor _textDark = PdfColor.fromInt(0xFF212121);
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _divider = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor _background = PdfColor.fromInt(0xFFF5F5F5);

  /// Generates a complete patient health report PDF
  /// Returns PDF bytes ready for printing or saving
  Future<Uint8List> generateReport(PatientReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: pw.EdgeInsets.all(_margin),
        build: (pw.Context context) => [
          _buildHeader(data),
          pw.SizedBox(height: 20),
          _buildPatientInfo(data.patient),
          pw.SizedBox(height: 16),
          if (data.doctor != null) ...[
            _buildDoctorSection(data.doctor!),
            pw.SizedBox(height: 16),
          ],
          if (data.adherence != null) ...[
            _buildAdherenceSection(data.adherence!),
            pw.SizedBox(height: 16),
          ],
          _buildMedicationsSection(data.medications),
          pw.SizedBox(height: 16),
          _buildDoseHistorySection(data.doseHistory),
          pw.SizedBox(height: 16),
          _buildVitalsSection(data.vitals),
        ],
        footer: (pw.Context context) => _buildFooter(data.generatedAt, context),
      ),
    );

    return pdf.save();
  }

  /// 1. Header Section - App branding and report title
  pw.Widget _buildHeader(PatientReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DasTern',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient Health Report',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  DateFormat('dd MMM yyyy').format(data.generatedAt),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Patient Info Section
  pw.Widget _buildPatientInfo(PatientProfile patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 12),
          _buildInfoRow('Name:', patient.fullName),
          if (patient.dateOfBirth != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow(
              'Date of Birth:',
              DateFormat('dd MMM yyyy').format(patient.dateOfBirth!),
            ),
          ],
          if (patient.age != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Age:', '${patient.age} years'),
          ],
          if (patient.gender != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Gender:', _formatGender(patient.gender!)),
          ],
          if (patient.email != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Email:', patient.email!),
          ],
          if (patient.phoneNumber != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Phone:', patient.phoneNumber!),
          ],
          if (patient.userId != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Patient ID:', patient.userId!),
          ],
        ],
      ),
    );
  }

  /// 3. Assigned Doctor Section
  pw.Widget _buildDoctorSection(DoctorInfo doctor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _background,
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assigned Doctor',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 12),
          _buildInfoRow('Name:', doctor.fullName),
          if (doctor.specialty != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Specialty:', doctor.specialty!),
          ],
          if (doctor.hospitalClinic != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Hospital/Clinic:', doctor.hospitalClinic!),
          ],
          if (doctor.licenseNumber != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('License Number:', doctor.licenseNumber!),
          ],
          if (doctor.email != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Email:', doctor.email!),
          ],
          if (doctor.phoneNumber != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoRow('Phone:', doctor.phoneNumber!),
          ],
        ],
      ),
    );
  }

  /// 3.5. Adherence Metrics Section
  pw.Widget _buildAdherenceSection(AdherenceMetrics adherence) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _background,
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Adherence Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              if (adherence.weeklyPercentage != null)
                _buildMetricCard(
                  'Weekly',
                  '${adherence.weeklyPercentage!.toStringAsFixed(0)}%',
                ),
              if (adherence.monthlyPercentage != null)
                _buildMetricCard(
                  'Monthly',
                  '${adherence.monthlyPercentage!.toStringAsFixed(0)}%',
                ),
              if (adherence.todayTaken != null && adherence.todayTotal != null)
                _buildMetricCard(
                  'Today',
                  '${adherence.todayTaken}/${adherence.todayTotal}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: _textGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Medications Section
  pw.Widget _buildMedicationsSection(List<Prescription> medications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Active Medications',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.SizedBox(height: 12),
        if (medications.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _divider),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'No active medications',
              style: pw.TextStyle(color: _textGrey),
            ),
          )
        else
          ...medications.expand((prescription) => [
            _buildPrescriptionCard(prescription),
            pw.SizedBox(height: 12),
          ]),
      ],
    );
  }

  pw.Widget _buildPrescriptionCard(Prescription prescription) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Prescription #${prescription.id?.substring(0, 8) ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _getStatusColor(prescription.status),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  prescription.status.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (prescription.diagnosis != null) ...[
            _buildInfoRow('Diagnosis:', prescription.diagnosis!),
            pw.SizedBox(height: 6),
          ],
          if (prescription.symptoms.isNotEmpty) ...[
            _buildInfoRow('Symptoms:', prescription.symptoms),
            pw.SizedBox(height: 6),
          ],
          pw.Divider(color: _divider, height: 16),
          pw.Text(
            'Medications:',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 8),
          ...prescription.medications.map((med) => _buildMedicationRow(med)),
          if (prescription.notes != null) ...[
            pw.SizedBox(height: 8),
            pw.Divider(color: _divider),
            pw.SizedBox(height: 8),
            _buildInfoRow('Notes:', prescription.notes!),
          ],
          if (prescription.startDate != null || prescription.endDate != null) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (prescription.startDate != null)
                  pw.Text(
                    'Start: ${DateFormat('dd/MM/yyyy').format(prescription.startDate!)}',
                    style: pw.TextStyle(fontSize: 9, color: _textGrey),
                  ),
                if (prescription.endDate != null)
                  pw.Text(
                    'End: ${DateFormat('dd/MM/yyyy').format(prescription.endDate!)}',
                    style: pw.TextStyle(fontSize: 9, color: _textGrey),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildMedicationRow(PrescriptionMedication med) {
    final schedule = _buildScheduleString(med);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _background,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  med.medicineName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              if (med.isPRN)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _primaryColor,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'PRN',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          if (med.medicineType != null)
            pw.Text(
              'Type: ${med.medicineType}',
              style: pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
          if (schedule.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Schedule: $schedule',
              style: pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
          ],
          if (med.frequency.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Frequency: ${med.frequency}',
              style: pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
          ],
          if (med.timing.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Timing: ${med.beforeMeal ? "Before meals" : "After meals"}',
              style: pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
          ],
          if (med.duration != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Duration: ${med.duration} days',
              style: pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
          ],
          if (med.additionalNote != null && med.additionalNote!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Note: ${med.additionalNote}',
              style: pw.TextStyle(fontSize: 9, color: _textGrey, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _buildScheduleString(PrescriptionMedication med) {
    final parts = <String>[];

    if (med.morningDosage != null) {
      final amount = med.morningDosage!['amount'] ?? 0;
      parts.add('Morning: $amount ${med.unit ?? ""}');
    }
    if (med.afternoonDosage != null) {
      final amount = med.afternoonDosage!['amount'] ?? 0;
      parts.add('Afternoon: $amount ${med.unit ?? ""}');
    }
    if (med.eveningDosage != null) {
      final amount = med.eveningDosage!['amount'] ?? 0;
      parts.add('Evening: $amount ${med.unit ?? ""}');
    }
    if (med.nightDosage != null) {
      final amount = med.nightDosage!['amount'] ?? 0;
      parts.add('Night: $amount ${med.unit ?? ""}');
    }

    return parts.join(', ');
  }

  /// 5. Dose History Section
  pw.Widget _buildDoseHistorySection(List<DoseEvent> doses) {
    // Group doses by date
    final grouped = <String, List<DoseEvent>>{};
    for (final dose in doses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(dose.scheduledTime);
      grouped.putIfAbsent(dateKey, () => []).add(dose);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dose Activity History (Last 30 Days)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.SizedBox(height: 12),
        if (doses.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _divider),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'No dose history recorded',
              style: pw.TextStyle(color: _textGrey),
            ),
          )
        else
          ...sortedDates.take(10).expand((dateKey) {
            final dateDoses = grouped[dateKey]!;
            final date = DateTime.parse(dateKey);

            return [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: _background,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  DateFormat('EEEE, dd MMM yyyy').format(date),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              ...dateDoses.map((dose) => _buildDoseRow(dose)),
              pw.SizedBox(height: 10),
            ];
          }),
      ],
    );
  }

  pw.Widget _buildDoseRow(DoseEvent dose) {
    final statusColor = _getDoseStatusColor(dose.status);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  dose.medicationName,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${DateFormat('HH:mm').format(dose.scheduledTime)} • ${_formatTimePeriod(dose.timePeriod)} • ${dose.dosage}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: statusColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              _formatDoseStatus(dose.status),
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Health Vitals Section
  pw.Widget _buildVitalsSection(List<HealthVital> vitals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Health Vitals',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.SizedBox(height: 12),
        if (vitals.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _divider),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'No vitals recorded',
              style: pw.TextStyle(color: _textGrey),
            ),
          )
        else
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: vitals.take(6).map((vital) => _buildVitalCard(vital)).toList(),
          ),
      ],
    );
  }

  pw.Widget _buildVitalCard(HealthVital vital) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: vital.isAbnormal ? PdfColors.red : _divider),
        borderRadius: pw.BorderRadius.circular(8),
        color: vital.isAbnormal ? PdfColor.fromInt(0xFFFFEBEE) : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            vital.vitalType.displayName,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${vital.displayValue} ${vital.unit}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: vital.isAbnormal ? PdfColors.red : _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            DateFormat('dd MMM, HH:mm').format(vital.measuredAt),
            style: pw.TextStyle(fontSize: 8, color: _textGrey),
          ),
          if (vital.notes != null && vital.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              vital.notes!,
              style: pw.TextStyle(fontSize: 8, color: _textGrey, fontStyle: pw.FontStyle.italic),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  /// 7. Footer Section
  pw.Widget _buildFooter(DateTime generatedAt, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _divider)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Report generated on ${DateFormat('dd MMM yyyy, HH:mm').format(generatedAt)}',
            style: pw.TextStyle(fontSize: 9, color: _textGrey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _textGrey),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Helper Widgets
  // ══════════════════════════════════════════════════════════════════

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textGrey,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: _textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Helper Functions
  // ══════════════════════════════════════════════════════════════════

  String _formatGender(String gender) {
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
        return 'Other';
      default:
        return gender;
    }
  }

  String _formatTimePeriod(String period) {
    switch (period.toUpperCase()) {
      case 'MORNING':
        return 'Morning';
      case 'AFTERNOON':
        return 'Afternoon';
      case 'EVENING':
        return 'Evening';
      case 'NIGHT':
        return 'Night';
      default:
        return period;
    }
  }

  String _formatDoseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DUE':
        return 'Due';
      case 'TAKEN_ON_TIME':
        return 'Taken';
      case 'TAKEN_LATE':
        return 'Late';
      case 'MISSED':
        return 'Missed';
      case 'SKIPPED':
        return 'Skipped';
      default:
        return status;
    }
  }

  PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PdfColors.green;
      case 'paused':
        return PdfColors.orange;
      case 'inactive':
        return PdfColors.grey;
      case 'draft':
        return PdfColors.blue;
      default:
        return _textGrey;
    }
  }

  PdfColor _getDoseStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DUE':
        return PdfColors.blue;
      case 'TAKEN_ON_TIME':
        return PdfColors.green;
      case 'TAKEN_LATE':
        return PdfColors.orange;
      case 'MISSED':
        return PdfColors.red;
      case 'SKIPPED':
        return PdfColors.grey;
      default:
        return _textGrey;
    }
  }
}
