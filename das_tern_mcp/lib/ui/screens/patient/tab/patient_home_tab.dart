import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/dose_event_model/dose_event.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../../models/enums_model/medication_type.dart';
import '../../../../core/router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/dose_task_card.dart';
import '../../../widgets/header_widgets.dart';
import 'patient_medications_tab.dart';
import '../screens/activity_report_screen.dart';

/// Patient home tab – daily dashboard.
/// Sections: header · medication tracker · progress · today's doses · quick actions · vitals
class PatientHomeTab extends StatefulWidget {
  const PatientHomeTab({super.key});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoseProvider>().fetchTodaySchedule();
      context.read<HealthMonitoringProvider>().fetchLatestVitals();
      context.read<HealthMonitoringProvider>().fetchAlerts();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      await Future.wait([
        context.read<DoseProvider>().fetchTodaySchedule(),
        context.read<HealthMonitoringProvider>().fetchLatestVitals(),
        context.read<HealthMonitoringProvider>().fetchAlerts(),
        context.read<NotificationProvider>().fetchNotifications(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doseProvider = context.watch<DoseProvider>();
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final subProvider = context.watch<SubscriptionProvider>();
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Sticky patient header ──
          PatientHeader(
            showBackButton: false,
            onNotificationTap: () {
              final notifProv = context.read<NotificationProvider>();
              Navigator.pushNamed(context, AppRouter.patientNotifications).then(
                (_) {
                  if (!mounted) return;
                  notifProv.fetchNotifications();
                },
              );
            },
            unreadCount: notifProvider.unreadCount,
          ),

          // ── Scrollable content ──
          SliverToBoxAdapter(
            child: Padding(
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
                    _formatDate(context, DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Time period cards ── UPDATED: uses period instead of backgroundImage
                  Row(
                    children: [
                      Expanded(
                        child: _TimePeriodCard(
                          label: l10n.morning,
                          icon: Icons.wb_sunny_outlined,
                          doseCount: _getDoseCountByPeriod(
                            doseProvider,
                            'MORNING',
                          ),
                          badgeText: l10n.beforeMeal,
                          period: 'MORNING',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientMedicationsTab(period: 'MORNING'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TimePeriodCard(
                          label: l10n.afternoon,
                          icon: Icons.wb_twilight,
                          doseCount: _getDoseCountByPeriod(
                            doseProvider,
                            'AFTERNOON',
                          ),
                          badgeText: l10n.afternoon,
                          period: 'AFTERNOON',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientMedicationsTab(period: 'AFTERNOON'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePeriodCard(
                          label: l10n.evening,
                          icon: Icons.wb_twilight,
                          doseCount: _getDoseCountByPeriod(
                            doseProvider,
                            'EVENING',
                          ),
                          badgeText: l10n.evening,
                          period: 'EVENING',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientMedicationsTab(period: 'EVENING'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TimePeriodCard(
                          label: l10n.night,
                          icon: Icons.nightlight_round,
                          doseCount: _getDoseCountByPeriod(
                            doseProvider,
                            'NIGHT',
                          ),
                          badgeText: l10n.night,
                          period: 'NIGHT',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientMedicationsTab(period: 'NIGHT'),
                            ),
                          ),
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
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: doseProvider.monthlyProgress,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                                color: AppColors.primaryBlue,
                              ),
                              Text(
                                '${doseProvider.effectiveDailyProgressCount} ${l10n.daysUnit}',
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
                                l10n.dayProgress(
                                  doseProvider.effectiveDailyProgressCount,
                                ),
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

                  // ── Today's doses ──
                  Builder(
                    builder: (context) {
                      final allDoses = doseProvider.todaysDoses;
                      const periodOrder = [
                        'MORNING',
                        'AFTERNOON',
                        'EVENING',
                        'NIGHT',
                      ];
                      final pendingByPeriod = <String, List<DoseEvent>>{};
                      final doneDoses = <DoseEvent>[];
                      for (final d in allDoses) {
                        final isDone =
                            d.status == 'TAKEN_ON_TIME' ||
                            d.status == 'TAKEN_LATE' ||
                            d.status == 'SKIPPED';
                        if (isDone) {
                          doneDoses.add(d);
                        } else {
                          pendingByPeriod
                              .putIfAbsent(d.timePeriod, () => [])
                              .add(d);
                        }
                      }
                      final allPending = <DoseEvent>[
                        for (final p in periodOrder)
                          ...pendingByPeriod[p] ?? [],
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.checklist, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  l10n.todaysTasks,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (allPending.length >= 2)
                                TextButton(
                                  onPressed: () => _showMarkAllDoneSheet(
                                    context,
                                    allPending,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: Text(
                                    l10n.markAllDone,
                                    style: const TextStyle(fontSize: 12),
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
                          else if (allDoses.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
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
                                  const Icon(
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
                          else ...[
                            if (allPending.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.noPendingDoses,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              for (final period in periodOrder)
                                if (pendingByPeriod[period]?.isNotEmpty ??
                                    false) ...[
                                  _PeriodSectionHeader(period: period),
                                  const SizedBox(height: AppSpacing.xs),
                                  ...pendingByPeriod[period]!.map(
                                    (d) => DoseTaskCard(dose: d),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                ],

                            if (doneDoses.isNotEmpty)
                              Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.zero,
                                  title: Text(
                                    l10n.completedCount(doneDoses.length),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  children: doneDoses
                                      .map(
                                        (dose) => DoseTaskCard(
                                          dose: dose,
                                          readOnly: true,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Quick actions ──
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

                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActivityReportScreen(),
                      ),
                    ),
                    child: _QuickActionCard(
                      icon: Icons.history,
                      title: l10n.medicationIntakeHistory,
                      color: const Color(0xFF0288D1),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  GestureDetector(
                    onTap: () {
                      if (subProvider.isPremium) {
                        Navigator.pushNamed(
                          context,
                          AppRouter.familyAccessList,
                        );
                      } else {
                        _showPremiumFamilyDialog(context);
                      }
                    },
                    child: _QuickActionCard(
                      icon: Icons.family_restroom,
                      title: l10n.familyFeatures,
                      color: const Color(0xFF29B6F6),
                      showPremiumBadge: !subProvider.isPremium,
                    ),
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
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.alertRed,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.unresolvedAlerts(
                                healthProvider.unresolvedAlertCount,
                              ),
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
                            color: Theme.of(context).colorScheme.surface,
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
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.tune,
                                  size: 20,
                                  color: AppColors.primaryBlue,
                                ),
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
                              color: AppColors.alertRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.emergency,
                                  size: 20,
                                  color: AppColors.alertRed,
                                ),
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

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAllDoneSheet(BuildContext context, List<DoseEvent> pending) {
    final l10n = AppLocalizations.of(context)!;
    final doseProvider = context.read<DoseProvider>();
    final selected = List<bool>.filled(pending.length, true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final checkedCount = selected.where((s) => s).length;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.markAllDone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      l10n.selectDosesToMark,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pending.length,
                        itemBuilder: (_, i) {
                          final dose = pending[i];
                          final st = dose.scheduledTime;
                          final timeStr =
                              '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
                          return CheckboxListTile(
                            value: selected[i],
                            onChanged: (v) =>
                                setSheetState(() => selected[i] = v ?? false),
                            title: Text(dose.medicationName),
                            subtitle: Text('${dose.dosage}  ·  $timeStr'),
                            activeColor: AppColors.successGreen,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: checkedCount == 0
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                for (int i = 0; i < pending.length; i++) {
                                  if (selected[i]) {
                                    await doseProvider.markTaken(
                                      pending[i].id ?? '',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.successGreen
                              .withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text(
                          '${l10n.markAllDone} ($checkedCount)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getDoseCountByPeriod(DoseProvider provider, String period) {
    return provider.todaysDoses
        .where((d) => d.timePeriod.toUpperCase() == period)
        .length;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    if (isKhmer) {
      const weekdays = [
        'ចន្ទ',
        'អង្គារ',
        'ពុធ',
        'ព្រហស្បតិ',
        'សុក្រ',
        'សៅរ៍',
        'អាទិត្យ',
      ];
      const months = [
        'មករា',
        'កុម្ភៈ',
        'មីនា',
        'មេសា',
        'ឧសភា',
        'មិថុនា',
        'កក្កដា',
        'សីហា',
        'កញ្ញា',
        'តុលា',
        'វិច្ឆិកា',
        'ធ្នូ',
      ];
      return 'ថ្ងៃ${weekdays[date.weekday - 1]} ទី${date.day} ${months[date.month - 1]}';
    } else {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
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
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  void _showPremiumFamilyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.warningOrange, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.premiumFeature)),
          ],
        ),
        content: Text(l10n.familyAlertsRequirePremium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRouter.subscriptionUpgrade);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.upgradeNow),
          ),
        ],
      ),
    );
  }

  IconData _vitalIcon(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return Icons.favorite;
      case VitalType.heartRate:
        return Icons.favorite_outline;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.glucose:
        return Icons.bloodtype;
      case VitalType.spo2:
        return Icons.air;
      case VitalType.weight:
        return Icons.scale;
    }
  }
}

// ── _TimePeriodCard ──────────────────────────────────────────────────────────
// UPDATED: replaces asset image background with gradient + healthcare symbols

class _TimePeriodCard extends StatelessWidget {
  const _TimePeriodCard({
    required this.label,
    required this.icon,
    required this.doseCount,
    required this.badgeText,
    required this.period,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final int doseCount;
  final String badgeText;
  final String period; // 'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT'
  final VoidCallback? onTap;

  List<Color> get _gradientColors {
    switch (period) {
      case 'MORNING':
        return [const Color(0xFFFF8C42), const Color(0xFFFFB347)];
      case 'AFTERNOON':
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case 'EVENING':
        return [const Color(0xFF4776E6), const Color(0xFF8E54E9)];
      case 'NIGHT':
        return [const Color(0xFF1A1A2E), const Color(0xFF0F3460)];
      default:
        return [AppColors.primaryBlue, AppColors.primaryBlue];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _gradientColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(
              children: [
                // decorative circle top-right
                Positioned(
                  top: -16,
                  right: -16,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // decorative circle bottom-left
                Positioned(
                  bottom: -20,
                  left: -10,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // large + cross
                Positioned(
                  top: 6,
                  right: 10,
                  child: Opacity(
                    opacity: 0.18,
                    child: CustomPaint(
                      size: const Size(26, 26),
                      painter: _CrossPainter(color: Colors.white),
                    ),
                  ),
                ),
                // small + cross
                Positioned(
                  bottom: 10,
                  right: 38,
                  child: Opacity(
                    opacity: 0.12,
                    child: CustomPaint(
                      size: const Size(16, 16),
                      painter: _CrossPainter(color: Colors.white),
                    ),
                  ),
                ),
                // pill shape
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Opacity(
                    opacity: 0.13,
                    child: CustomPaint(
                      size: const Size(30, 13),
                      painter: _PillPainter(color: Colors.white),
                    ),
                  ),
                ),
                // main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      style: const TextStyle(
                        color: Colors.white70,
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
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
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
          ),
        ),
      ),
    );
  }
}

// ── Healthcare + cross painter ───────────────────────────────────────────────

class _CrossPainter extends CustomPainter {
  final Color color;
  const _CrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    final third = size.width / 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(third, 0, third, size.height),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, third, size.width, third),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Pill shape painter ────────────────────────────────────────────────────────

class _PillPainter extends CustomPainter {
  final Color color;
  const _PillPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
      paint,
    );
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── _QuickActionCard ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    this.showPremiumBadge = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool showPremiumBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                showPremiumBadge ? Icons.lock : Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
        if (showPremiumBadge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warningOrange,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Period section header ─────────────────────────────────────────────────────

class _PeriodSectionHeader extends StatelessWidget {
  const _PeriodSectionHeader({required this.period});
  final String period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, label) = switch (period) {
      'MORNING' => (Icons.wb_twilight, const Color(0xFFFFA726), l10n.morning),
      'AFTERNOON' => (Icons.wb_sunny, const Color(0xFFFFD600), l10n.afternoon),
      'EVENING' => (
        Icons.wb_cloudy_outlined,
        const Color(0xFFFF7043),
        l10n.evening,
      ),
      'NIGHT' => (Icons.bedtime, const Color(0xFF5C6BC0), l10n.night),
      _ => (Icons.access_time, AppColors.textSecondary, period),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
