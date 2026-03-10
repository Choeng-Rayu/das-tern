import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/adherence_provider.dart';
import '../../../../providers/dose_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Displays a comprehensive adherence and activity summary for the patient.
/// Sections:
///   1. Summary cards (today, weekly, monthly adherence %)
///   2. Weekly day-by-day breakdown
///   3. Dose history list (last 30 days)
class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adherence = context.watch<AdherenceProvider>();
    final dose = context.watch<DoseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.activityReport),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  // ── Summary Cards ──────────────────────────────────────
                  _SummaryCards(adherence: adherence, l10n: l10n),
                  const SizedBox(height: AppSpacing.md),

                  // ── Weekly Breakdown ───────────────────────────────────
                  _WeeklyBreakdown(
                    adherence: adherence,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Dose History ───────────────────────────────────────
                  _DoseHistorySection(dose: dose, isDark: isDark, l10n: l10n),
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
          _TodayStatsRow(adherence: adherence, l10n: l10n),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _CircularPercent(percentage: percentage, color: color, size: 72),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
              trackColor: color.withValues(alpha: 0.12),
            ),
          ),
          Text(
            '${pct.round()}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: color,
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
        rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({required this.adherence, required this.l10n});

  final AdherenceProvider adherence;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taken = adherence.todayTaken;
    final total = adherence.todayTotal;
    final missed = total - taken;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatBadge(
            label: l10n.totalDoses,
            value: '$total',
            color: AppColors.primaryBlue,
          ),
          _StatBadge(
            label: l10n.taken,
            value: '$taken',
            color: AppColors.statusSuccess,
          ),
          _StatBadge(
            label: l10n.missed,
            value: '$missed',
            color: AppColors.statusError,
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
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Weekly Breakdown ──────────────────────────────────────────────────────────

class _WeeklyBreakdown extends StatelessWidget {
  const _WeeklyBreakdown({
    required this.adherence,
    required this.isDark,
    required this.l10n,
  });

  final AdherenceProvider adherence;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final days =
        (adherence.weeklyAdherence?['days'] as List<dynamic>?) ?? [];

    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.weeklyAdherence),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map<Widget>((dayData) {
              final map = dayData as Map<String, dynamic>;
              final label = (map['dayLabel'] as String?) ??
                  (map['date'] as String? ?? '').split('-').last;
              final pct =
                  (map['percentage'] as num?)?.toDouble().clamp(0.0, 100.0) ??
                  0.0;
              return _DayBar(label: label, percentage: pct);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.label, required this.percentage});

  final String label;
  final double percentage;

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
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Dose History ──────────────────────────────────────────────────────────────

class _DoseHistorySection extends StatelessWidget {
  const _DoseHistorySection({
    required this.dose,
    required this.isDark,
    required this.l10n,
  });

  final DoseProvider dose;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.doseHistory),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: dose.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : dose.history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: AppColors.neutral300,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.noHistoryYet,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dose.history.length,
                  separatorBuilder: (ctx, idx) => Divider(
                    height: 1,
                    indent: 56,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final d = dose.history[index];
                    final isTaken = d.status.contains('TAKEN');
                    final isLate = d.status == 'TAKEN_LATE';
                    final isSkipped = d.status == 'SKIPPED';
                    final icon = isTaken
                        ? Icons.check_circle
                        : isSkipped
                        ? Icons.skip_next
                        : Icons.cancel;
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
                    final time = d.scheduledTime;
                    final timeStr =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    final dateStr = '${time.day}/${time.month}/${time.year}';

                    return ListTile(
                      leading: Icon(icon, color: iconColor),
                      title: Text(
                        d.medicationName,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '$dateStr  $timeStr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
