import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/dose_event_model/dose_event.dart';
import '../../../../models/prescription_model/prescription.dart';
import '../../../../models/health_model/health_vital.dart';
import '../../../../models/patient_report_data.dart';
import '../../../../providers/adherence_provider.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/prescription_provider.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../../services/patient_report_pdf_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/language_switcher.dart';

/// Displays a comprehensive patient health report and activity summary.
/// Sections:
///   1. Patient header card (name, DOB, age, gender, assigned doctor)
///   2. Medication summary (detailed per-medication info)
///   3. Summary cards (today, weekly, monthly adherence %)
///   4. Weekly day-by-day breakdown
///   5. Dose history list (last 30 days) - grouped by date
///   6. Health vitals section (blood pressure, other vitals)
///   7. Report timestamp footer
/// The "Download PDF" button is visible to all users; tapping it checks premium status.
class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  bool _generatingPdf = false;
  bool _isLoadingReportData = true;
  PatientReportData? _reportData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      context.read<AdherenceProvider>().fetchAll();
      context.read<DoseProvider>().fetchHistory(
        startDate: monthAgo.toIso8601String().split('T')[0],
        endDate: now.toIso8601String().split('T')[0],
      );
      // Fetch prescriptions for medication details and doctor info
      context.read<PrescriptionProvider>().fetchPrescriptions(status: 'ACTIVE');
      // Fetch latest health vitals
      context.read<HealthMonitoringProvider>().fetchLatestVitals();
      // Load report data for print/save functionality
      _loadReportData();
    });
  }

  /// Loads all required data for the report
  Future<void> _loadReportData() async {
    setState(() {
      _isLoadingReportData = true;
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
        doctorMap: null,
        prescriptions: prescriptionProvider.prescriptions,
        doses: doseProvider.history,
        healthVitals: healthProvider.vitals,
        adherenceData: {
          'weeklyPercentage':
              (adherenceProvider.weeklyAdherence?['percentage'] as num?)
                  ?.toDouble(),
          'monthlyPercentage':
              (adherenceProvider.monthlyAdherence?['percentage'] as num?)
                  ?.toDouble(),
          'todayTaken': adherenceProvider.todayTaken,
          'todayTotal': adherenceProvider.todayTotal,
          'weeklyDays': adherenceProvider.weeklyAdherence?['days'],
        },
      );

      setState(() {
        _isLoadingReportData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReportData = false;
      });
    }
  }

  /// Generates PDF and opens print preview dialog
  Future<void> _handlePrint() async {
    if (_reportData == null) return;
    final isPremium = context.read<SubscriptionProvider>().isPremium;
    if (!isPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() => _generatingPdf = true);

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
      setState(() => _generatingPdf = false);
    }
  }

  /// Generates PDF, saves to device, and opens share sheet
  Future<void> _handleSavePdf() async {
    if (_reportData == null) return;
    final isPremium = context.read<SubscriptionProvider>().isPremium;
    if (!isPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() => _generatingPdf = true);

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
      final box = context.findRenderObject() as RenderBox?;
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'DasTern Health Report',
        text: 'My health report from DasTern',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report saved successfully'),
            backgroundColor: AppColors.statusSuccess,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Open',
              textColor: theme.colorScheme.onPrimary,
              onPressed: () async {
                // Open the file using the system default app
                final box = context.findRenderObject() as RenderBox?;
                await Share.shareXFiles(
                  [XFile(file.path)],
                  sharePositionOrigin: box != null
                      ? (box.localToGlobal(Offset.zero) & box.size)
                      : null,
                );
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
      setState(() => _generatingPdf = false);
    }
  }

  /// Generates a filename for the PDF report
  String _generateFileName() {
    final patientName = _reportData?.patient.fullName ?? 'Patient';
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    // Clean patient name for filename (remove spaces and special characters)
    final cleanName = patientName
        .replaceAll(RegExp(r'[^\w]'), '_')
        .toLowerCase();
    return 'dastern_report_${cleanName}_$date.pdf';
  }

  void _showUpgradeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.lock_outline_rounded, size: 40),
        iconColor: AppColors.primaryBlue,
        title: Text(
          l10n.premiumFeature,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
        content: Text(
          l10n.downloadReportDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRouter.subscriptionUpgrade);
              },
              child: Text(l10n.upgradeToPremium),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.maybeLater,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adherence = context.watch<AdherenceProvider>();
    final dose = context.watch<DoseProvider>();
    final auth = context.watch<AuthProvider>();
    final prescription = context.watch<PrescriptionProvider>();
    final health = context.watch<HealthMonitoringProvider>();
    final cs = Theme.of(context).colorScheme;

    final isLoading =
        adherence.isLoading ||
        dose.isLoading ||
        prescription.isLoading ||
        health.isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          l10n.activityReport,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (_reportData != null && !_generatingPdf) ...[
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Header Card
                  _PatientHeaderCard(auth: auth, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Assigned Doctor Card (if available)
                  if (prescription.prescriptions.isNotEmpty &&
                      prescription.prescriptions.first.doctor != null) ...[
                    _AssignedDoctorCard(
                      doctor: prescription.prescriptions.first.doctor!,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 3. Medication Summary Section
                  if (prescription.prescriptions.isNotEmpty) ...[
                    _MedicationSummarySection(
                      prescriptions: prescription.prescriptions,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 4. Adherence Summary Cards
                  _SummaryCards(adherence: adherence, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Weekly Breakdown
                  _WeeklyBreakdown(adherence: adherence, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Dose History Section (grouped by date)
                  _DoseHistorySection(dose: dose, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Health Vitals Section
                  _HealthVitalsSection(health: health, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // 8. Report Timestamp Footer
                  _ReportTimestampFooter(),
                  const SizedBox(height: 100), // Space for bottom action bar
                ],
              ),
            ),
      bottomNavigationBar:
          _reportData != null && !_isLoadingReportData && !isLoading
          ? _buildBottomActionBar(l10n)
          : null,
    );
  }

  Widget _buildBottomActionBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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
                onPressed: _generatingPdf ? null : _handlePrint,
                icon: _generatingPdf
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
                onPressed: _generatingPdf ? null : _handleSavePdf,
                icon: _generatingPdf
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(l10n.saveAsPdf),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.adherence, required this.l10n});

  final AdherenceProvider adherence;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final weekly =
        (adherence.weeklyAdherence?['percentage'] as num?)?.toDouble() ?? 0.0;
    final monthly =
        (adherence.monthlyAdherence?['percentage'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.adherenceSummary),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _AdherenceCard(
                label: l10n.weeklyAdherence,
                percentage: weekly,
                color: AppColors.primaryBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdherenceDetailScreen(
                      title: l10n.weeklyAdherence,
                      percentage: weekly,
                      color: AppColors.primaryBlue,
                      adherenceData: adherence.weeklyAdherence,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AdherenceCard(
                label: l10n.monthlyAdherence,
                percentage: monthly,
                color: AppColors.successGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdherenceDetailScreen(
                      title: l10n.monthlyAdherence,
                      percentage: monthly,
                      color: AppColors.successGreen,
                      adherenceData: adherence.monthlyAdherence,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (adherence.todayAdherence != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _TodayStatsRow(adherence: adherence, l10n: l10n, cs: cs),
        ],
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({
    required this.label,
    required this.percentage,
    required this.color,
    this.onTap,
  });

  final String label;
  final double percentage;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            children: [
              _CircularPercent(percentage: percentage, color: color, size: 72),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See details',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 14, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularPercent extends StatelessWidget {
  const _CircularPercent({
    required this.percentage,
    required this.color,
    this.size = 80,
  });

  final double percentage;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = percentage.clamp(0.0, 100.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress: pct / 100,
              color: color,
              trackColor: cs.outlineVariant,
            ),
          ),
          Text(
            '${pct.round()}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({
    required this.adherence,
    required this.l10n,
    required this.cs,
  });

  final AdherenceProvider adherence;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final taken = adherence.todayTaken;
    final total = adherence.todayTotal;
    final missed = total - taken;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatBadge(
            label: l10n.totalDoses,
            value: '$total',
            color: AppColors.primaryBlue,
            cs: cs,
          ),
          _StatBadge(
            label: l10n.taken,
            value: '$taken',
            color: AppColors.statusSuccess,
            cs: cs,
          ),
          _StatBadge(
            label: l10n.missed,
            value: '$missed',
            color: AppColors.statusError,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Weekly Breakdown ──────────────────────────────────────────────────────────

class _WeeklyBreakdown extends StatelessWidget {
  const _WeeklyBreakdown({required this.adherence, required this.l10n});

  final AdherenceProvider adherence;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = (adherence.weeklyAdherence?['days'] as List<dynamic>?) ?? [];

    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.weeklyAdherence),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map<Widget>((dayData) {
              final map = dayData as Map<String, dynamic>;
              final label =
                  (map['dayLabel'] as String?) ??
                  (map['date'] as String? ?? '').split('-').last;
              final pct =
                  (map['percentage'] as num?)?.toDouble().clamp(0.0, 100.0) ??
                  0.0;
              return _DayBar(label: label, percentage: pct, cs: cs);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.percentage,
    required this.cs,
  });

  final String label;
  final double percentage;
  final ColorScheme cs;

  static const double _maxHeight = 80;

  @override
  Widget build(BuildContext context) {
    final barHeight = (_maxHeight * percentage / 100).clamp(4.0, _maxHeight);
    final color = percentage >= 80
        ? AppColors.statusSuccess
        : percentage >= 50
        ? AppColors.statusWarning
        : AppColors.statusError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${percentage.round()}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Dose History ──────────────────────────────────────────────────────────────

class _DoseHistorySection extends StatelessWidget {
  const _DoseHistorySection({required this.dose, required this.l10n});

  final DoseProvider dose;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Group doses by date
    final groupedByDate = <String, List<DoseEvent>>{};
    for (final event in dose.history) {
      final dateKey = DateFormat.yMMMd().format(event.scheduledTime);
      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(event);
    }

    // Sort dates descending (most recent first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) {
        final dateA = groupedByDate[a]!.first.scheduledTime;
        final dateB = groupedByDate[b]!.first.scheduledTime;
        return dateB.compareTo(dateA);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.doseHistory),
        const SizedBox(height: AppSpacing.sm),
        if (dose.isLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (dose.history.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.noHistoryYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final dateKey in sortedDates) ...[
                // Date subheader
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  child: Text(
                    dateKey,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                // Doses for this date
                ...groupedByDate[dateKey]!.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DoseHistoryCard(event: event, l10n: l10n),
                  );
                }),
              ],
            ],
          ),
      ],
    );
  }
}

class _DoseHistoryCard extends StatelessWidget {
  const _DoseHistoryCard({required this.event, required this.l10n});

  final DoseEvent event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = event;

    final isTaken = d.status.contains('TAKEN');
    final isLate = d.status == 'TAKEN_LATE';
    final isSkipped = d.status == 'SKIPPED';
    final iconData = isTaken
        ? Icons.check_circle_rounded
        : isSkipped
        ? Icons.skip_next_rounded
        : Icons.cancel_rounded;
    final statusColor = isTaken
        ? (isLate ? AppColors.statusWarning : AppColors.statusSuccess)
        : AppColors.statusError;
    final statusLabel = isTaken
        ? (isLate ? l10n.late : l10n.onTime)
        : isSkipped
        ? 'Skipped'
        : l10n.missed;
    final t = d.scheduledTime;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final dateStr = '${t.day}/${t.month}/${t.year}';

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoseDetailScreen(event: d, l10n: l10n),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(iconData, color: statusColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.medicationName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateStr  ·  $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.cs,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dose Detail Screen ────────────────────────────────────────────────────────

class DoseDetailScreen extends StatelessWidget {
  const DoseDetailScreen({super.key, required this.event, required this.l10n});

  final DoseEvent event;
  final AppLocalizations l10n;

  String _formatTimePeriod(String period) {
    switch (period) {
      case 'MORNING':
        return 'Morning';
      case 'AFTERNOON':
        return 'Afternoon';
      case 'EVENING':
        return 'Evening';
      case 'NIGHT':
        return 'Night';
      case 'DAYTIME':
        return 'Daytime';
      default:
        return period;
    }
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d  ·  $t';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = event;

    final isTaken = d.status.contains('TAKEN');
    final isLate = d.status == 'TAKEN_LATE';
    final isSkipped = d.status == 'SKIPPED';
    final iconData = isTaken
        ? Icons.check_circle_rounded
        : isSkipped
        ? Icons.skip_next_rounded
        : Icons.cancel_rounded;
    final statusColor = isTaken
        ? (isLate ? AppColors.statusWarning : AppColors.statusSuccess)
        : AppColors.statusError;
    final statusLabel = isTaken
        ? (isLate ? l10n.late : l10n.onTime)
        : isSkipped
        ? 'Skipped'
        : l10n.missed;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          d.medicationName,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status hero card ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(iconData, color: statusColor, size: 52),
                  const SizedBox(height: 10),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(d.scheduledTime),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Detail section ─────────────────────────────────────────────
            _SectionTitle(title: 'Dose Details'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Medication',
                    value: d.medicationName,
                    cs: cs,
                    icon: Icons.medication_rounded,
                  ),
                  Divider(height: 16, color: cs.outlineVariant),
                  if (d.dosage.isNotEmpty) ...[
                    _DetailRow(
                      label: 'Dosage',
                      value: d.dosage,
                      cs: cs,
                      icon: Icons.scale_rounded,
                    ),
                    Divider(height: 16, color: cs.outlineVariant),
                  ],
                  _DetailRow(
                    label: 'Time Period',
                    value: _formatTimePeriod(d.timePeriod),
                    cs: cs,
                    icon: Icons.schedule_rounded,
                  ),
                  Divider(height: 16, color: cs.outlineVariant),
                  _DetailRow(
                    label: 'Scheduled',
                    value: _formatDateTime(d.scheduledTime),
                    cs: cs,
                    icon: Icons.calendar_today_rounded,
                  ),
                  if (d.takenAt != null) ...[
                    Divider(height: 16, color: cs.outlineVariant),
                    _DetailRow(
                      label: 'Taken At',
                      value: _formatDateTime(d.takenAt!),
                      cs: cs,
                      icon: Icons.done_all_rounded,
                      valueColor: AppColors.statusSuccess,
                    ),
                  ],
                  if (d.reminderTime != null) ...[
                    Divider(height: 16, color: cs.outlineVariant),
                    _DetailRow(
                      label: 'Reminder',
                      value: d.reminderTime!,
                      cs: cs,
                      icon: Icons.notifications_outlined,
                    ),
                  ],
                ],
              ),
            ),

            // ── Skip / offline info ────────────────────────────────────────
            if (isSkipped && d.skipReason != null && d.skipReason!.isNotEmpty ||
                d.wasOffline) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionTitle(title: 'Additional Info'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    if (isSkipped &&
                        d.skipReason != null &&
                        d.skipReason!.isNotEmpty)
                      _DetailRow(
                        label: 'Skip Reason',
                        value: d.skipReason!,
                        cs: cs,
                        icon: Icons.info_outline_rounded,
                        valueColor: AppColors.statusError,
                      ),
                    if (d.wasOffline) ...[
                      if (isSkipped &&
                          d.skipReason != null &&
                          d.skipReason!.isNotEmpty)
                        Divider(height: 16, color: cs.outlineVariant),
                      _DetailRow(
                        label: 'Recorded',
                        value: 'While offline',
                        cs: cs,
                        icon: Icons.wifi_off_rounded,
                        valueColor: AppColors.statusWarning,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Download PDF Button ───────────────────────────────────────────────────────

// ── Adherence Detail Screen ───────────────────────────────────────────────────

class AdherenceDetailScreen extends StatelessWidget {
  const AdherenceDetailScreen({
    super.key,
    required this.title,
    required this.percentage,
    required this.color,
    this.adherenceData,
  });

  final String title;
  final double percentage;
  final Color color;
  final Map<String, dynamic>? adherenceData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = (adherenceData?['days'] as List<dynamic>?) ?? [];
    final taken = (adherenceData?['taken'] as num?)?.toInt() ?? 0;
    final total = (adherenceData?['total'] as num?)?.toInt() ?? 0;
    final missed = total - taken;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Big adherence circle ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  _CircularPercent(
                    percentage: percentage,
                    color: color,
                    size: 110,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // ── Taken / Missed summary ────────────────────────────────────
            if (total > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _AdherenceStat(
                      label: 'Taken',
                      value: '$taken',
                      color: AppColors.statusSuccess,
                      icon: Icons.check_circle_outline_rounded,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdherenceStat(
                      label: 'Missed',
                      value: '$missed',
                      color: AppColors.statusError,
                      icon: Icons.cancel_outlined,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdherenceStat(
                      label: 'Total',
                      value: '$total',
                      color: AppColors.primaryBlue,
                      icon: Icons.medication_rounded,
                      cs: cs,
                    ),
                  ),
                ],
              ),
            ],

            // ── Day-by-day breakdown ──────────────────────────────────────
            if (days.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: 'Day by Day'),
              const SizedBox(height: AppSpacing.sm),
              ...days.map((dayData) {
                final map = dayData as Map<String, dynamic>;
                final label =
                    (map['dayLabel'] as String?) ??
                    (map['date'] as String? ?? '').split('-').last;
                final date = map['date'] as String? ?? '';
                final pct =
                    (map['percentage'] as num?)?.toDouble().clamp(0.0, 100.0) ??
                    0.0;
                final dayTaken = (map['taken'] as num?)?.toInt();
                final dayTotal = (map['total'] as num?)?.toInt();
                final dayMissed =
                    (map['missed'] as num?)?.toInt() ??
                    (dayTotal != null && dayTaken != null
                        ? dayTotal - dayTaken
                        : null);
                final barColor = pct >= 80
                    ? AppColors.statusSuccess
                    : pct >= 50
                    ? AppColors.statusWarning
                    : AppColors.statusError;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: barColor, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const Spacer(),
                        if (dayMissed != null && dayMissed > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusError.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$dayMissed missed',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusError,
                              ),
                            ),
                          ),
                        Text(
                          '${pct.round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No detailed breakdown available',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _AdherenceStat extends StatelessWidget {
  const _AdherenceStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.cs,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Patient Header Card ───────────────────────────────────────────────────────

class _PatientHeaderCard extends StatelessWidget {
  const _PatientHeaderCard({required this.auth, required this.l10n});

  final AuthProvider auth;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = auth.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isEmpty ? l10n.patient : fullName;

    final dateOfBirth = user['dateOfBirth'] != null
        ? DateTime.tryParse(user['dateOfBirth'] as String)
        : null;
    final age = dateOfBirth != null
        ? DateTime.now().difference(dateOfBirth).inDays ~/ 365
        : null;

    final genderStr = user['gender'] as String?;
    final gender = genderStr != null ? _formatGender(genderStr) : null;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.primaryBlue,
                size: 36,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (dateOfBirth != null)
                    Text(
                      '${l10n.dateOfBirth}: ${DateFormat.yMMMd().format(dateOfBirth)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (age != null)
                    Text(
                      '${l10n.age}: $age ${l10n.yearsUnit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (gender != null)
                    Text(
                      '${l10n.gender}: $gender',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}

// ── Assigned Doctor Card ──────────────────────────────────────────────────────

class _AssignedDoctorCard extends StatelessWidget {
  const _AssignedDoctorCard({required this.doctor, required this.l10n});

  final Map<String, dynamic> doctor;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctorName = doctor['fullName'] as String? ?? 'Doctor';
    final specialty = doctor['specialty'] as String? ?? '';
    final hospitalClinic = doctor['hospitalClinic'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.assignedDoctor),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.successGreen.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.successGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                      if (specialty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      if (hospitalClinic.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          hospitalClinic,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Medication Summary Section ────────────────────────────────────────────────

class _MedicationSummarySection extends StatelessWidget {
  const _MedicationSummarySection({
    required this.prescriptions,
    required this.l10n,
  });

  final List<Prescription> prescriptions;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.medications),
        const SizedBox(height: AppSpacing.sm),
        ...prescriptions.expand((prescription) {
          return prescription.medications.map((med) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MedicationCard(
                medication: med,
                prescription: prescription,
                l10n: l10n,
              ),
            );
          });
        }),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.prescription,
    required this.l10n,
  });

  final PrescriptionMedication medication;
  final Prescription prescription;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build schedule summary
    final scheduleSlots = <String>[];
    if (medication.morningDosage != null) scheduleSlots.add(l10n.morning);
    if (medication.afternoonDosage != null) scheduleSlots.add(l10n.afternoon);
    if (medication.eveningDosage != null) scheduleSlots.add(l10n.evening);
    if (medication.nightDosage != null) scheduleSlots.add(l10n.night);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication name
            Text(
              medication.medicineName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Medicine type and unit
            if (medication.medicineType != null)
              _InfoRow(
                icon: Icons.medical_information_outlined,
                label: l10n.form,
                value: medication.medicineType!,
                cs: cs,
              ),
            if (medication.dosageAmount != null && medication.unit != null)
              _InfoRow(
                icon: Icons.medication_outlined,
                label: l10n.dosage,
                value: '${medication.dosageAmount} ${medication.unit}',
                cs: cs,
              ),

            // Frequency
            if (medication.frequency.isNotEmpty)
              _InfoRow(
                icon: Icons.schedule,
                label: l10n.frequency,
                value: medication.frequency,
                cs: cs,
              ),

            // Schedule slots
            if (scheduleSlots.isNotEmpty)
              _InfoRow(
                icon: Icons.access_time,
                label: l10n.schedule,
                value: scheduleSlots.join(', '),
                cs: cs,
              ),

            // Meal timing
            if (medication.timing.isNotEmpty)
              _InfoRow(
                icon: Icons.restaurant_outlined,
                label: l10n.timing,
                value: medication.timing,
                cs: cs,
              ),

            // PRN flag
            if (medication.isPRN)
              _InfoRow(
                icon: Icons.info_outline,
                label: l10n.typeLabel,
                value: l10n.prn,
                cs: cs,
              ),

            // Duration
            if (medication.duration != null)
              _InfoRow(
                icon: Icons.event,
                label: l10n.durationDays,
                value: '${medication.duration} ${l10n.days}',
                cs: cs,
              ),

            // Start and end dates from prescription
            if (prescription.startDate != null)
              _InfoRow(
                icon: Icons.calendar_today,
                label: l10n.startDate,
                value: DateFormat.yMMMd().format(prescription.startDate!),
                cs: cs,
              ),
            if (prescription.endDate != null)
              _InfoRow(
                icon: Icons.event_available,
                label: l10n.endDate,
                value: DateFormat.yMMMd().format(prescription.endDate!),
                cs: cs,
              ),

            // Additional notes
            if (medication.additionalNote != null &&
                medication.additionalNote!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.additionalNote!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Vitals Section ─────────────────────────────────────────────────────

class _HealthVitalsSection extends StatelessWidget {
  const _HealthVitalsSection({required this.health, required this.l10n});

  final HealthMonitoringProvider health;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vitals = health.latestVitals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.healthVitals),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: vitals.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.noVitalsRecorded,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: vitals.map((vital) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _VitalRow(vital: vital, l10n: l10n),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _VitalRow extends StatelessWidget {
  const _VitalRow({required this.vital, required this.l10n});

  final HealthVital vital;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formattedDate = DateFormat.yMMMd().add_jm().format(vital.measuredAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getVitalColor(vital.vitalType).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getVitalIcon(vital.vitalType),
            color: _getVitalColor(vital.vitalType),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vital.vitalType.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${vital.displayValue} ${vital.unit}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getVitalIcon(dynamic vitalType) {
    final typeStr = vitalType.toString();
    if (typeStr.contains('bloodPressure')) return Icons.favorite;
    if (typeStr.contains('glucose')) return Icons.water_drop;
    if (typeStr.contains('heartRate')) return Icons.monitor_heart;
    if (typeStr.contains('weight')) return Icons.scale;
    if (typeStr.contains('temperature')) return Icons.thermostat;
    if (typeStr.contains('spo2')) return Icons.air;
    return Icons.health_and_safety;
  }

  Color _getVitalColor(dynamic vitalType) {
    final typeStr = vitalType.toString();
    if (typeStr.contains('bloodPressure')) return AppColors.alertRed;
    if (typeStr.contains('glucose')) return AppColors.warningOrange;
    if (typeStr.contains('heartRate')) return AppColors.primaryBlue;
    if (typeStr.contains('weight')) return AppColors.successGreen;
    if (typeStr.contains('temperature')) return AppColors.warningOrange;
    if (typeStr.contains('spo2')) return AppColors.primaryBlue;
    return AppColors.primaryBlue;
  }
}

// ── Report Timestamp Footer ───────────────────────────────────────────────────

class _ReportTimestampFooter extends StatelessWidget {
  const _ReportTimestampFooter();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final formattedDate = DateFormat.yMMMMd().add_jm().format(now);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report generated on:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formattedDate,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            'Das Tern v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
