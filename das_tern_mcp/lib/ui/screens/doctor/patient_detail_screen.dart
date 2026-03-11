import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../models/doctor_dashboard_model/doctor_dashboard_models.dart';
import '../../../models/enums_model/medication_type.dart';
import '../../../models/health_model/health_vital.dart';
import '../../../services/api_service.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Doctor's view of a specific patient's details:
/// basic info, prescriptions, adherence timeline, and notes.
class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DoctorDashboardProvider>();
      provider.fetchPatientDetails(widget.patientId);
      provider.fetchNotes(widget.patientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DoctorDashboardProvider>();
    final details = provider.selectedPatientDetails;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(details?.patient.displayName ?? l10n.patient)),
      body: provider.detailsLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
          ? Center(
              child: Text(
                provider.error ?? l10n.failedToLoadPatientDetails,
                style: TextStyle(color: AppColors.alertRed),
              ),
            )
          : Column(
              children: [
                // Patient Profile Card
                _PatientProfileCard(
                  patient: details.patient,
                  adherence: details.adherence,
                  isDark: isDark,
                ),
                // Tab navigation
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: l10n.overview),
                            Tab(text: l10n.prescriptions),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _OverviewTab(details: details),
                              _PrescriptionsTab(details: details),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Patient Profile Card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PatientProfileCard extends StatelessWidget {
  final PatientInfo patient;
  final AdherenceResult adherence;
  final bool isDark;

  const _PatientProfileCard({
    required this.patient,
    required this.adherence,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? Colors.grey[850] : Colors.grey[50],
      child: Card(
        elevation: isDark ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and basic info
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      patient.displayName.isNotEmpty
                          ? patient.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (patient.age != null)
                              Text(
                                '${patient.age} yrs',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            if (patient.age != null && patient.gender != null)
                              const SizedBox(width: 8),
                            if (patient.gender != null)
                              Text(
                                patient.gender ?? '',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Adherence metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricColumn(
                    label: 'Adherence',
                    value: '${adherence.overallPercentage.toStringAsFixed(0)}%',
                    color: _adherenceColor(adherence.level),
                  ),
                  _MetricColumn(
                    label: 'Taken',
                    value: '${adherence.takenDoses}',
                    color: AppColors.successGreen,
                  ),
                  _MetricColumn(
                    label: 'Missed',
                    value: '${adherence.missedDoses}',
                    color: AppColors.alertRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _adherenceColor(String? level) {
    switch (level) {
      case 'GREEN':
        return AppColors.successGreen;
      case 'YELLOW':
        return AppColors.warningOrange;
      case 'RED':
        return AppColors.alertRed;
      default:
        return AppColors.neutralGray;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Prescriptions Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PrescriptionsTab extends StatelessWidget {
  final PatientDetails details;

  const _PrescriptionsTab({required this.details});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prescriptions = details.prescriptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prescriptions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: AppColors.neutral300,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noPrescriptions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            ...prescriptions.map((rx) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                elevation: isDark ? 2 : 1,
                color: isDark
                    ? Colors.grey[850]
                    : Theme.of(context).cardTheme.color,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: rx.isActive
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.neutral300.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: rx.isActive
                          ? AppColors.successGreen
                          : AppColors.neutralGray,
                    ),
                  ),
                  title: Text(
                    rx.symptoms ?? l10n.prescription,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${rx.medications.length} ${rx.medications.length == 1 ? 'medicine' : l10n.medications}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: rx.isActive
                                  ? AppColors.successGreen.withValues(
                                      alpha: 0.15,
                                    )
                                  : AppColors.neutral300.withValues(
                                      alpha: 0.15,
                                    ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rx.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: rx.isActive
                                    ? AppColors.successGreen
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _formatDate(rx.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Overview Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _OverviewTab extends StatelessWidget {
  final PatientDetails details;
  const _OverviewTab({required this.details});

  @override
  Widget build(BuildContext context) {
    final patient = details.patient;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info
          Text(
            'Patient Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Age', value: '${patient.age ?? 'N/A'}'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(label: 'Gender', value: patient.gender ?? 'N/A'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(label: 'Phone', value: patient.phoneNumber ?? 'N/A'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(label: 'Email', value: patient.email ?? 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Vitals Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _VitalsTab extends StatefulWidget {
  final String patientId;
  const _VitalsTab({required this.patientId});

  @override
  State<_VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends State<_VitalsTab> {
  List<HealthVital> _vitals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.getPatientVitals(widget.patientId);
      setState(() {
        _vitals = data.map((j) => HealthVital.fromJson(j)).toList()
          ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.alertRed)),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(onPressed: _loadVitals, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (_vitals.isEmpty) {
      return Center(child: Text(l10n.noVitalReadings));
    }

    // Group by vital type for latest summary
    final latestByType = <VitalType, HealthVital>{};
    for (final v in _vitals) {
      if (!latestByType.containsKey(v.vitalType)) {
        latestByType[v.vitalType] = v;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadVitals,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.latestReadings,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.8,
              children: latestByType.entries.map((entry) {
                final vital = entry.value;
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: vital.isAbnormal
                        ? AppColors.alertRed.withValues(alpha: 0.08)
                        : AppColors.successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: vital.isAbnormal
                          ? AppColors.alertRed.withValues(alpha: 0.3)
                          : AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vital.vitalType.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vital.displayValue} ${vital.unit}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vital.isAbnormal
                              ? AppColors.alertRed
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${vital.measuredAt.day}/${vital.measuredAt.month}/${vital.measuredAt.year}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.historyCount(_vitals.length),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._vitals
                .take(50)
                .map(
                  (vital) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 6,
                        height: 36,
                        decoration: BoxDecoration(
                          color: vital.isAbnormal
                              ? AppColors.alertRed
                              : AppColors.successGreen,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      title: Text(
                        '${vital.vitalType.displayName}: ${vital.displayValue} ${vital.unit}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${vital.measuredAt.day}/${vital.measuredAt.month}/${vital.measuredAt.year} '
                        '${vital.measuredAt.hour.toString().padLeft(2, '0')}:'
                        '${vital.measuredAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: vital.isAbnormal
                          ? const Icon(
                              Icons.warning,
                              color: AppColors.alertRed,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
