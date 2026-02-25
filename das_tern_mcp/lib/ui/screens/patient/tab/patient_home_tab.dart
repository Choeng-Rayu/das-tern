import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../../models/enums_model/medication_type.dart';
import '../../../../utils/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Patient home tab – daily dashboard matching Figma design.
/// Shows greeting, time-period medicine cards, progress circle,
/// today's dose checklist, and quick-action section.
class PatientHomeTab extends StatefulWidget {
  const PatientHomeTab({super.key});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoseProvider>().fetchTodaySchedule();
      context.read<HealthMonitoringProvider>().fetchLatestVitals();
      context.read<HealthMonitoringProvider>().fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final doseProvider = context.watch<DoseProvider>();
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final user = auth.user;
    final firstName = user?['firstName'] ?? l10n.defaultPatientName;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => doseProvider.fetchTodaySchedule(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Blue header section ──
              AppGradientHeader(
                greeting: l10n.greetingName(firstName),
                trailing: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // ── Time-period medicine section ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.medicationTracker,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ថ្ងៃ អាទិត្យ- ទី ${DateTime.now().day}- ${_khmerMonth(DateTime.now().month)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Time period cards row
                    Row(
                      children: [
                        Expanded(
                          child: _TimePeriodCard(
                            label: l10n.morning,
                            icon: Icons.wb_sunny_outlined,
                            color: AppColors.morningYellow,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'MORNING'),
                            badgeText: l10n.beforeMeal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimePeriodCard(
                            label: l10n.afternoon,
                            icon: Icons.wb_twilight,
                            color: AppColors.afternoonOrange,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'AFTERNOON'),
                            badgeText: l10n.afternoon,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimePeriodCard(
                            label: l10n.night,
                            icon: Icons.nightlight_round,
                            color: AppColors.nightPurple,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'NIGHT'),
                            badgeText: l10n.night,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Progress circle section ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          // Progress circle
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: doseProvider.progress,
                                  strokeWidth: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.5),
                                  color: AppColors.primaryBlue,
                                ),
                                Text(
                                  '${(doseProvider.progress * 30).toInt()} ${l10n.daysUnit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryBlue,
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
                                Text(
                                  l10n.progressMessage,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.dayProgress((doseProvider.progress * 30).toInt()),
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.totalDuration,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Today's doses (checklist) ──
                    Row(
                      children: [
                        const Icon(Icons.checklist, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.todaysTasks,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (doseProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (doseProvider.todaysDoses.isEmpty)
                      Container(
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                      )
                    else
                      ...doseProvider.todaysDoses.map(
                        (dose) => _DoseCheckItem(
                          name: dose.medicationName,
                          dosage: dose.dosage,
                          isTaken: dose.status == 'TAKEN',
                          onTake: () =>
                              doseProvider.markTaken(dose.id ?? ''),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Quick actions (មុខងារសំខាន់ៗ) ──
                    Text(
                      l10n.quickActions,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                    const SizedBox(height: AppSpacing.lg),

                    // ── Health Vitals Section ──
                    if (healthProvider.unresolvedAlertCount > 0)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.alertRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppColors.alertRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.alertRed, size: 24),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.unresolvedAlerts(healthProvider.unresolvedAlertCount),
                                style: const TextStyle(
                                  color: AppColors.alertRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.healthVitals,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRouter.patientRecordVital,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l10n.recordLabel),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Vital cards grid
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
                        final hasValue = vital != null;
                        final isAbnormal = vital?.isAbnormal ?? false;

                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.patientVitalTrend,
                            arguments: {'vitalType': type},
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isAbnormal
                                    ? AppColors.alertRed.withValues(alpha: 0.5)
                                    : AppColors.neutral300,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
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
                                      const Icon(Icons.warning,
                                          color: AppColors.alertRed,
                                          size: 14),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasValue
                                      ? vital.displayValue
                                      : '--',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isAbnormal
                                        ? AppColors.alertRed
                                        : AppColors.textPrimary,
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
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Thresholds & Emergency row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.patientVitalThresholds,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.tune,
                                      size: 20,
                                      color: AppColors.primaryBlue),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    l10n.thresholds,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.patientEmergency,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.alertRed
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emergency,
                                      size: 20,
                                      color: AppColors.alertRed),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    l10n.emergencyLabel,
                                    style: const TextStyle(
                                      color: AppColors.alertRed,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

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

  int _getDoseCountByPeriod(DoseProvider provider, String period) {
    return provider.todaysDoses
        .where((d) => d.timePeriod.toUpperCase() == period)
        .length;
  }

  String _khmerMonth(int month) {
    const months = [
      'មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
      'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ',
    ];
    return months[month - 1];
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

// ── Time period card matching Figma ──
class _TimePeriodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int doseCount;
  final String badgeText;

  const _TimePeriodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.doseCount,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            l10n.medicineCountLabel(doseCount),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
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
    );
  }
}

// ── Dose check item matching Figma ──
class _DoseCheckItem extends StatelessWidget {
  final String name;
  final String dosage;
  final bool isTaken;
  final VoidCallback onTake;

  const _DoseCheckItem({
    required this.name,
    required this.dosage,
    required this.isTaken,
    required this.onTake,
  });

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
                color: isTaken
                    ? AppColors.primaryBlue
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
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

// ── Quick action card ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
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
        ],
      ),
    );
  }
}
