import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../../models/enums_model/medication_type.dart';
import '../../../../utils/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/header_widgets.dart';

/// Patient home tab – daily dashboard.
/// Sections: header · medication tracker · progress · today's doses · quick actions · vitals
class PatientHomeTab extends StatefulWidget {
  const PatientHomeTab({super.key});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab> {
  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoseProvider>().fetchTodaySchedule();
      context.read<HealthMonitoringProvider>().fetchLatestVitals();
      context.read<HealthMonitoringProvider>().fetchAlerts();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final doseProvider = context.watch<DoseProvider>();
    final healthProvider = context.watch<HealthMonitoringProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => doseProvider.fetchTodaySchedule(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              PatientHeader(
                onNotificationTap: () {
                  final route = AppRouter.patientNotifications;
                  if (route != null) Navigator.pushNamed(context, route);
                },
                unreadCount: healthProvider.unresolvedAlertCount,
              ),

              // ── Body sections ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MedicationTrackerSection(doseProvider: doseProvider),
                    const SizedBox(height: AppSpacing.lg),
                    _ProgressSection(doseProvider: doseProvider),
                    const SizedBox(height: AppSpacing.lg),
                    _TodaysDosesSection(doseProvider: doseProvider),
                    const SizedBox(height: AppSpacing.lg),
                    _QuickActionsSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _HealthVitalsSection(healthProvider: healthProvider),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Medication Tracker
// ═══════════════════════════════════════════════════════════════════════════════

class _MedicationTrackerSection extends StatelessWidget {
  const _MedicationTrackerSection({required this.doseProvider});

  final DoseProvider doseProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          l10n.medicationTracker,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        // Date subtitle
        Text(
          '${_dayName(now.weekday)} - ${now.day} ${_khmerMonth(now.month)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),

        // Time-period cards row
        Row(
          children: [
            Expanded(
              child: _TimePeriodCard(
                label: l10n.morning,
                icon: Icons.wb_sunny_outlined,
                color: AppColors.morningYellow,
                doseCount: _getDoseCountByPeriod(doseProvider, 'MORNING'),
                badgeText: l10n.beforeMeal,
                backgroundImage: 'assets/morning.png',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TimePeriodCard(
                label: l10n.afternoon,
                icon: Icons.wb_twilight,
                color: AppColors.afternoonOrange,
                doseCount: _getDoseCountByPeriod(doseProvider, 'AFTERNOON'),
                badgeText: l10n.afternoon,
                backgroundImage: 'assets/afternoon.png',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TimePeriodCard(
                label: l10n.night,
                icon: Icons.nightlight_round,
                color: AppColors.nightPurple,
                doseCount: _getDoseCountByPeriod(doseProvider, 'NIGHT'),
                badgeText: l10n.night,
                backgroundImage: 'assets/night.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getDoseCountByPeriod(DoseProvider provider, String period) => provider
      .todaysDoses
      .where((d) => d.timePeriod.toUpperCase() == period)
      .length;

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _khmerMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Progress Circle
// ═══════════════════════════════════════════════════════════════════════════════

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.doseProvider});

  final DoseProvider doseProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysCompleted = (doseProvider.progress * 30).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // Circle progress
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: doseProvider.progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '$daysCompleted\n${l10n.daysUnit}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressRow(text: l10n.progressMessage),
                const SizedBox(height: 6),
                _ProgressRow(
                  text: l10n.dayProgress(daysCompleted),
                  isBold: true,
                ),
                const SizedBox(height: 6),
                _ProgressRow(text: l10n.totalDuration),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.text, this.isBold = false});

  final String text;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5, right: 6),
          child: Icon(Icons.arrow_forward, color: Colors.white70, size: 12),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Today's Doses
// ═══════════════════════════════════════════════════════════════════════════════

class _TodaysDosesSection extends StatelessWidget {
  const _TodaysDosesSection({required this.doseProvider});

  final DoseProvider doseProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon
        Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.todaysTasks,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          l10n.afternoon,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Content
        if (doseProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else if (doseProvider.todaysDoses.isEmpty)
          _EmptyDoseState()
        else
          ...doseProvider.todaysDoses.map(
            (dose) => _DoseCheckItem(
              name: dose.medicationName,
              dosage: dose.dosage,
              isTaken: dose.status == 'TAKEN',
              onTake: () => doseProvider.markTaken(dose.id ?? ''),
            ),
          ),
      ],
    );
  }
}

class _EmptyDoseState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppColors.successGreen,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.allCompleted,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.noMoreMedicationsToday,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Quick Actions
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionCard(
          icon: Icons.translate,
          title: l10n.searchPrescription,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.history,
                title: l10n.medicationIntakeHistory,
                color: const Color(0xFF0288D1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.family_restroom,
                title: l10n.familyFeatures,
                color: const Color(0xFF29B6F6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Health Vitals
// ═══════════════════════════════════════════════════════════════════════════════

class _HealthVitalsSection extends StatelessWidget {
  const _HealthVitalsSection({required this.healthProvider});

  final HealthMonitoringProvider healthProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alert banner
        if (healthProvider.unresolvedAlertCount > 0) ...[
          _AlertBanner(count: healthProvider.unresolvedAlertCount),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.healthVitals,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.patientRecordVital),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.recordLabel),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Vitals grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: VitalType.values.map((type) {
            final vital = healthProvider.latestVitals
                .where((v) => v.vitalType == type)
                .firstOrNull;
            return _VitalCard(
              type: type,
              vital: vital,
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.patientVitalTrend,
                arguments: {'vitalType': type},
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Threshold & Emergency row
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.tune,
                label: l10n.thresholds,
                color: AppColors.primaryBlue,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.patientVitalThresholds,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                icon: Icons.emergency,
                label: l10n.emergencyLabel,
                color: AppColors.alertRed,
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.patientEmergency),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.alertRed,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.unresolvedAlerts(count),
              style: const TextStyle(
                color: AppColors.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.type,
    required this.vital,
    required this.onTap,
  });

  final VitalType type;
  final dynamic vital;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = vital != null;
    final isAbnormal = vital?.isAbnormal ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isAbnormal
                ? AppColors.alertRed.withValues(alpha: 0.5)
                : AppColors.neutral300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  _vitalIcon(type),
                  size: 18,
                  color: isAbnormal
                      ? AppColors.alertRed
                      : AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAbnormal)
                  const Icon(
                    Icons.warning,
                    color: AppColors.alertRed,
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasValue ? vital.displayValue : '--',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isAbnormal ? AppColors.alertRed : AppColors.textPrimary,
              ),
            ),
            Text(
              type.unit,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _vitalIcon(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return Icons.favorite;
      case VitalType.glucose:
        return Icons.water_drop;
      case VitalType.heartRate:
        return Icons.monitor_heart;
      case VitalType.weight:
        return Icons.monitor_weight;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.spo2:
        return Icons.air;
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _TimePeriodCard extends StatelessWidget {
  const _TimePeriodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.doseCount,
    required this.badgeText,
    this.backgroundImage,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int doseCount;
  final String badgeText;
  final String? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Dark overlay
          if (backgroundImage != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          // Content
          Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.medicineCountLabel(doseCount),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseCheckItem extends StatelessWidget {
  const _DoseCheckItem({
    required this.name,
    required this.dosage,
    required this.isTaken,
    required this.onTake,
  });

  final String name;
  final String dosage;
  final bool isTaken;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isTaken ? AppColors.successGreen : AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  dosage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.onePill,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isTaken ? null : onTake,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isTaken ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryBlue, width: 2),
              ),
              child: isTaken
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}
