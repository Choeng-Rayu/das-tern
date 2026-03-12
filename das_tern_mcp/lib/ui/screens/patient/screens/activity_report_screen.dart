import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/dose_event_model/dose_event.dart';
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
                  _DownloadPdfButton(
                    generatingPdf: _generatingPdf,
                    onTap: _onDownloadTapped,
                    l10n: l10n,
                  ),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (dose.history.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < dose.history.length; i++) ...[
                _DoseHistoryCard(event: dose.history[i], l10n: l10n),
                if (i < dose.history.length - 1) const SizedBox(height: 8),
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
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
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
  const DoseDetailScreen({
    super.key,
    required this.event,
    required this.l10n,
  });

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
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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

class _DownloadPdfButton extends StatelessWidget {
  const _DownloadPdfButton({
    required this.generatingPdf,
    required this.onTap,
    required this.l10n,
  });

  final bool generatingPdf;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: generatingPdf ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: generatingPdf
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.picture_as_pdf_rounded,
                        color: cs.onPrimary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generatingPdf ? l10n.generatingPdf : l10n.downloadPdf,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Premium feature · Tap to export',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: cs.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final days =
        (adherenceData?['days'] as List<dynamic>?) ?? [];
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
                  _CircularPercent(percentage: percentage, color: color, size: 110),
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
                final label = (map['dayLabel'] as String?) ??
                    (map['date'] as String? ?? '').split('-').last;
                final date = map['date'] as String? ?? '';
                final pct =
                    (map['percentage'] as num?)?.toDouble().clamp(0.0, 100.0) ??
                        0.0;
                final dayTaken = (map['taken'] as num?)?.toInt();
                final dayTotal = (map['total'] as num?)?.toInt();
                final dayMissed = (map['missed'] as num?)?.toInt() ??
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
                        horizontal: 16, vertical: 14),
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
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusError.withValues(alpha: 0.12),
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
