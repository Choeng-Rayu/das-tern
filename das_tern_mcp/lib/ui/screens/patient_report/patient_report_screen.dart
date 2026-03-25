import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/patient_report_data.dart';
import '../../../models/dose_event_model/dose_event.dart';
import '../../../models/prescription_model/prescription.dart';
import '../../../models/health_model/health_vital.dart';
import '../../../providers/adherence_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dose_provider.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../../providers/prescription_provider.dart';
import '../../../services/patient_report_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/language_switcher.dart';

/// Patient Report Screen with Print and Save as PDF functionality.
/// Fetches all patient health data and provides export options.
class PatientReportScreen extends StatefulWidget {
  const PatientReportScreen({super.key});

  @override
  State<PatientReportScreen> createState() => _PatientReportScreenState();
}

class _PatientReportScreenState extends State<PatientReportScreen> {
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  PatientReportData? _reportData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Fetches all required data from providers and constructs PatientReportData
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final prescriptionProvider = context.read<PrescriptionProvider>();
      final doseProvider = context.read<DoseProvider>();
      final healthProvider = context.read<HealthMonitoringProvider>();
      final adherenceProvider = context.read<AdherenceProvider>();

      // Fetch prescriptions if not already loaded
      if (prescriptionProvider.prescriptions.isEmpty) {
        await prescriptionProvider.fetchPrescriptions();
      }

      // Fetch dose history (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      await doseProvider.fetchHistory(
        startDate: DateFormat('yyyy-MM-dd').format(thirtyDaysAgo),
        endDate: DateFormat('yyyy-MM-dd').format(now),
      );

      // Fetch health vitals if not already loaded
      if (healthProvider.vitals.isEmpty) {
        await healthProvider.fetchVitals();
      }

      // Fetch adherence data
      await adherenceProvider.fetchAll();

      // Construct PatientReportData
      _reportData = PatientReportData.fromProviders(
        userMap: auth.user,
        doctorMap: null, // TODO: Add doctor info if available from provider
        prescriptions: prescriptionProvider.prescriptions,
        doses: doseProvider.history,
        healthVitals: healthProvider.vitals,
        adherenceData: {
          'weeklyPercentage': (adherenceProvider.weeklyAdherence?['percentage'] as num?)?.toDouble(),
          'monthlyPercentage': (adherenceProvider.monthlyAdherence?['percentage'] as num?)?.toDouble(),
          'todayTaken': adherenceProvider.todayTaken,
          'todayTotal': adherenceProvider.todayTotal,
          'weeklyDays': adherenceProvider.weeklyAdherence?['days'],
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load report data: $e';
      });
    }
  }

  /// Generates PDF and opens print preview dialog
  Future<void> _handlePrint() async {
    if (_reportData == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final pdfService = PatientReportPdfService();
      final pdfBytes = await pdfService.generateReport(_reportData!);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: _generateFileName(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Print preview opened'),
          backgroundColor: AppColors.statusSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: AppColors.statusError,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Generates PDF, saves to device, and opens share sheet
  Future<void> _handleSavePdf() async {
    if (_reportData == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final pdfService = PatientReportPdfService();
      final pdfBytes = await pdfService.generateReport(_reportData!);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'DasTern Health Report',
        text: 'My health report from DasTern',
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report saved successfully'),
            backgroundColor: AppColors.statusSuccess,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                // Open the file using the system default app
                await Share.shareXFiles([XFile(file.path)]);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save report: $e'),
          backgroundColor: AppColors.statusError,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Generates a filename for the PDF report
  String _generateFileName() {
    final patientName = _reportData?.patient.fullName ?? 'Patient';
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    // Clean patient name for filename (remove spaces and special characters)
    final cleanName = patientName.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
    return 'dastern_report_${cleanName}_$date.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthReport),
        actions: [
          if (_reportData != null && !_isGeneratingPdf) ...[
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: l10n.print,
              onPressed: _handlePrint,
            ),
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: l10n.saveAsPdf,
              onPressed: _handleSavePdf,
            ),
          ],
          const LanguageSwitcherButton(lightBackground: true),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(l10n),
      bottomNavigationBar: _reportData != null && !_isLoading
          ? _buildBottomActionBar(l10n)
          : null,
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.statusError,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error Loading Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No report data available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return _buildReportPreview(l10n);
  }

  Widget _buildReportPreview(AppLocalizations l10n) {
    final data = _reportData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          _buildSectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Patient Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildInfoRow(l10n.name, data.patient.fullName),
                if (data.patient.dateOfBirth != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    l10n.dateOfBirth,
                    DateFormat('dd MMM yyyy').format(data.patient.dateOfBirth!),
                  ),
                ],
                if (data.patient.age != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    l10n.age,
                    '${data.patient.age} ${l10n.years}',
                  ),
                ],
                if (data.patient.gender != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(l10n.gender, data.patient.gender!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Adherence Summary
          if (data.adherence != null) ...[
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Adherence Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (data.adherence!.weeklyPercentage != null)
                        _buildMetricCard(
                          'Weekly',
                          '${data.adherence!.weeklyPercentage!.toStringAsFixed(0)}%',
                          isDark,
                        ),
                      if (data.adherence!.monthlyPercentage != null)
                        _buildMetricCard(
                          'Monthly',
                          '${data.adherence!.monthlyPercentage!.toStringAsFixed(0)}%',
                          isDark,
                        ),
                      if (data.adherence!.todayTaken != null &&
                          data.adherence!.todayTotal != null)
                        _buildMetricCard(
                          'Today',
                          '${data.adherence!.todayTaken}/${data.adherence!.todayTotal}',
                          isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Medications Section
          _buildSectionHeader('Active Medications (${data.medications.length})'),
          const SizedBox(height: AppSpacing.sm),
          if (data.medications.isEmpty)
            _buildSectionCard(
              isDark: isDark,
              child: Text(
                'No active medications',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...data.medications.map(
              (prescription) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildPrescriptionCard(prescription, isDark),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Dose History Section
          _buildSectionHeader('Dose History (${data.doseHistory.length} entries)'),
          const SizedBox(height: AppSpacing.sm),
          if (data.doseHistory.isEmpty)
            _buildSectionCard(
              isDark: isDark,
              child: Text(
                'No dose history recorded',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...data.doseHistory.take(10).map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _buildDoseCard(dose, isDark),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Health Vitals Section
          _buildSectionHeader('Health Vitals (${data.vitals.length} readings)'),
          const SizedBox(height: AppSpacing.sm),
          if (data.vitals.isEmpty)
            _buildSectionCard(
              isDark: isDark,
              child: Text(
                'No vitals recorded',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: data.vitals.take(6).map((vital) {
                return _buildVitalCard(vital, isDark);
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.md),

          // Report Footer
          _buildSectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report generated on:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(data.generatedAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DasTern v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80), // Space for bottom action bar
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
              child: OutlinedButton.icon(
                onPressed: _isGeneratingPdf ? null : _handlePrint,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: Text(l10n.print),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primaryBlue),
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _handleSavePdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(l10n.saveAsPdf),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prescription #${prescription.id?.substring(0, 8) ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(prescription.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prescription.status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (prescription.medications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${prescription.medications.length} medication(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoseCard(DoseEvent dose, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.medicationName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, HH:mm').format(dose.scheduledTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDoseStatusColor(dose.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatDoseStatus(dose.status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(HealthVital vital, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: vital.isAbnormal
              ? AppColors.statusError
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vital.vitalType.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${vital.displayValue} ${vital.unit}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: vital.isAbnormal ? AppColors.statusError : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM, HH:mm').format(vital.measuredAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.statusSuccess;
      case 'paused':
        return AppColors.statusWarning;
      case 'inactive':
        return AppColors.neutral400;
      case 'draft':
        return AppColors.primaryBlue;
      default:
        return AppColors.neutral400;
    }
  }

  Color _getDoseStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DUE':
        return AppColors.primaryBlue;
      case 'TAKEN_ON_TIME':
        return AppColors.statusSuccess;
      case 'TAKEN_LATE':
        return AppColors.statusWarning;
      case 'MISSED':
        return AppColors.statusError;
      case 'SKIPPED':
        return AppColors.neutral400;
      default:
        return AppColors.neutral400;
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
}
