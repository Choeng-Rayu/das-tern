import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Full-screen success view shown after a prescription is saved.
/// Displays a celebration header, the prescription summary,
/// and the auto-generated time-slot schedule (Morning / Afternoon / Night).
class PrescriptionSuccessScreen extends StatelessWidget {
  final String prescriptionName;
  final String dateRange;
  final String? doctorName;
  final List<Map<String, dynamic>> medicines;

  const PrescriptionSuccessScreen({
    super.key,
    required this.prescriptionName,
    required this.dateRange,
    this.doctorName,
    required this.medicines,
  });

  // ── schedule helper ────────────────────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> _computeSchedule() {
    final schedule = <String, List<Map<String, dynamic>>>{};
    for (final med in medicines) {
      final morning =
          med['morning'] == true ||
          (med['scheduleTimes'] as List?)?.any(
                (t) => t['timePeriod'] == 'morning',
              ) ==
              true;
      final daytime =
          med['daytime'] == true ||
          (med['scheduleTimes'] as List?)?.any(
                (t) => t['timePeriod'] == 'daytime',
              ) ==
              true;
      final night =
          med['night'] == true ||
          (med['scheduleTimes'] as List?)?.any(
                (t) => t['timePeriod'] == 'night',
              ) ==
              true;

      if (morning) schedule.putIfAbsent('morning', () => []).add(med);
      if (daytime) schedule.putIfAbsent('afternoon', () => []).add(med);
      if (night) schedule.putIfAbsent('night', () => []).add(med);
    }
    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedule = _computeSchedule();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // ── celebration icon ──
                      _CelebrationHeader(l10n: l10n),
                      const SizedBox(height: AppSpacing.lg),
                      // ── prescription summary card ──
                      _SummaryCard(
                        name: prescriptionName,
                        dateRange: dateRange,
                        doctorName: doctorName,
                        medicineCount: medicines.length,
                        l10n: l10n,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // ── schedule header ──
                      _ScheduleHeader(l10n: l10n),
                      const SizedBox(height: AppSpacing.md),
                      // ── schedule slots ──
                      if (schedule.containsKey('morning'))
                        _ScheduleSlotCard(
                          period: l10n.morning,
                          time: l10n.morningTime,
                          icon: Icons.wb_sunny_rounded,
                          color: AppColors.morningYellow,
                          medicines: schedule['morning']!,
                        ),
                      if (schedule.containsKey('afternoon'))
                        _ScheduleSlotCard(
                          period: l10n.afternoon,
                          time: l10n.afternoonTime,
                          icon: Icons.wb_twilight,
                          color: AppColors.afternoonOrange,
                          medicines: schedule['afternoon']!,
                        ),
                      if (schedule.containsKey('night'))
                        _ScheduleSlotCard(
                          period: l10n.night,
                          time: l10n.nightTime,
                          icon: Icons.nightlight_round,
                          color: AppColors.nightPurple,
                          medicines: schedule['night']!,
                        ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              // ── bottom buttons ──
              _BottomActions(l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated celebration header with check icon and text.
class _CelebrationHeader extends StatelessWidget {
  final AppLocalizations l10n;
  const _CelebrationHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.successGreen.withValues(alpha: 0.15),
                AppColors.successGreen.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.successGreen,
            size: 56,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.prescriptionCreatedSuccess,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.yourScheduleReady,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Gradient summary card showing prescription name, dates, doctor, count.
class _SummaryCard extends StatelessWidget {
  final String name;
  final String dateRange;
  final String? doctorName;
  final int medicineCount;
  final AppLocalizations l10n;

  const _SummaryCard({
    required this.name,
    required this.dateRange,
    this.doctorName,
    required this.medicineCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF1A3BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateRange,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (doctorName != null && doctorName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  doctorName!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.medication_outlined,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.medicinesCount(medicineCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Schedule Preview" section header with icon and subtitle.
class _ScheduleHeader extends StatelessWidget {
  final AppLocalizations l10n;
  const _ScheduleHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.schedulePreview,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.scheduleAutoGenerated,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Color-coded time-slot card listing medicines for that period.
class _ScheduleSlotCard extends StatelessWidget {
  final String period;
  final String time;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> medicines;

  const _ScheduleSlotCard({
    required this.period,
    required this.time,
    required this.icon,
    required this.color,
    required this.medicines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          ...medicines.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(m['name'] ?? '', style: const TextStyle(fontSize: 13)),
                  if ((m['dosage'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      m['dosage'].toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two bottom action buttons: "View Schedule" and "Go Home".
class _BottomActions extends StatelessWidget {
  final AppLocalizations l10n;
  const _BottomActions({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // View schedule — secondary
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Pop back to patient home (schedule tab)
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(l10n.viewSchedule),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Go home — primary
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              icon: const Icon(Icons.home_outlined, size: 18),
              label: Text(l10n.goHome),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
