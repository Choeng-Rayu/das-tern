import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/adherence_provider.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../../utils/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Displays a comprehensive adherence and activity summary for the patient.
/// Sections:
///   1. Summary cards (today, weekly, monthly adherence %)
///   2. Weekly day-by-day breakdown
///   3. Dose history list (last 30 days)
/// The "Download PDF" button is visible to all users; tapping it checks premium status.
class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  bool _generatingPdf = false;

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
    });
  }

  // ── PDF logic ───────────────────────────────────────────────────────────────

  Future<void> _onDownloadTapped() async {
    final isPremium = context.read<SubscriptionProvider>().isPremium;
    if (!isPremium) {
      _showUpgradeDialog();
      return;
    }
    await _generateAndSharePdf();
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

  Future<void> _generateAndSharePdf() async {
    if (_generatingPdf) return;
    setState(() => _generatingPdf = true);

    final adherence = context.read<AdherenceProvider>();
    final dose = context.read<DoseProvider>();

    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final weekly =
          (adherence.weeklyAdherence?['percentage'] as num?)?.toDouble() ?? 0.0;
      final monthly =
          (adherence.monthlyAdherence?['percentage'] as num?)?.toDouble() ??
          0.0;
      final taken = adherence.todayTaken;
      final total = adherence.todayTotal;
      final days = (adherence.weeklyAdherence?['days'] as List<dynamic>?) ?? [];

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfCtx) => [
            // Header
            pw.Text(
              'DasTern – Activity Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated on $dateStr',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.Divider(height: 24),

            // Summary
            pw.Text(
              'Adherence Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Today – Taken / Total', '$taken / $total'],
                [
                  'Today – Adherence',
                  total > 0 ? '${(taken / total * 100).round()}%' : '0%',
                ],
                ['Weekly Adherence', '${weekly.round()}%'],
                ['Monthly Adherence', '${monthly.round()}%'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),

            // Weekly breakdown
            if (days.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Weekly Breakdown',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Day', 'Adherence'],
                data: days.map((d) {
                  final m = d as Map<String, dynamic>;
                  final label =
                      (m['dayLabel'] as String?) ??
                      (m['date'] as String? ?? '').split('-').last;
                  final pct = (m['percentage'] as num?)?.toDouble() ?? 0.0;
                  return [label, '${pct.round()}%'];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ],

            // Dose history
            if (dose.history.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Dose History (Last 30 Days)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Medication', 'Date', 'Time', 'Status'],
                data: dose.history.map((d) {
                  final t = d.scheduledTime;
                  return [
                    d.medicationName,
                    '${t.day}/${t.month}/${t.year}',
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                    d.status,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
              ),
            ],
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: 'DasTern_Report_$dateStr.pdf',
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adherence = context.watch<AdherenceProvider>();
    final dose = context.watch<DoseProvider>();
    final cs = Theme.of(context).colorScheme;

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
          _generatingPdf
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _onDownloadTapped,
                  tooltip: l10n.downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
        ],
      ),
      body: adherence.isLoading && dose.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCards(adherence: adherence, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                  _WeeklyBreakdown(adherence: adherence, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                  _DoseHistorySection(dose: dose, l10n: l10n),
                  const SizedBox(height: AppSpacing.xl),
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
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AdherenceCard(
                label: l10n.monthlyAdherence,
                percentage: monthly,
                color: AppColors.successGreen,
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
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
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
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.doseHistory),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: dose.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : dose.history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
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
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dose.history.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, indent: 60, color: cs.outlineVariant),
                  itemBuilder: (context, index) {
                    final d = dose.history[index];
                    final isTaken = d.status.contains('TAKEN');
                    final isLate = d.status == 'TAKEN_LATE';
                    final isSkipped = d.status == 'SKIPPED';
                    final icon = isTaken
                        ? Icons.check_circle_rounded
                        : isSkipped
                        ? Icons.skip_next_rounded
                        : Icons.cancel_rounded;
                    final iconColor = isTaken
                        ? (isLate
                              ? AppColors.statusWarning
                              : AppColors.statusSuccess)
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

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(icon, color: iconColor, size: 26),
                      title: Text(
                        d.medicationName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '$dateStr  $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
