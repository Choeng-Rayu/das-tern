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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          details?.patient.displayName ?? l10n.patient,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.overview),
            Tab(text: l10n.adherence),
            Tab(text: l10n.vitals),
            Tab(text: l10n.notes),
          ],
        ),
      ),
      body: provider.detailsLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
              ? Center(
                  child: Text(
                    provider.error ?? l10n.failedToLoadPatientDetails,
                    style: TextStyle(color: AppColors.alertRed),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(details: details),
                    _AdherenceTab(details: details),
                    _VitalsTab(patientId: widget.patientId),
                    _NotesTab(
                      patientId: widget.patientId,
                      noteController: _noteController,
                    ),
                  ],
                ),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final patient = details.patient;
    final adherence = details.adherence;
    final prescriptions = details.prescriptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          (patient.firstName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.ageLabel(patient.age?.toString() ?? 'N/A', patient.gender ?? 'N/A'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              patient.phoneNumber ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Adherence Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricColumn(
                    label: l10n.adherence,
                    value: '${adherence.overallPercentage.toStringAsFixed(0)}%',
                    color: _adherenceColor(adherence.level),
                  ),
                  _MetricColumn(
                    label: l10n.taken,
                    value: '${adherence.takenDoses}',
                    color: AppColors.successGreen,
                  ),
                  _MetricColumn(
                    label: l10n.missed,
                    value: '${adherence.missedDoses}',
                    color: AppColors.alertRed,
                  ),
                  _MetricColumn(
                    label: l10n.late,
                    value: '${adherence.lateDoses}',
                    color: AppColors.warningOrange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Prescriptions
          Text(
            l10n.activePrescriptionsCount(prescriptions.where((p) => p.isActive).length),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (prescriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text(l10n.noPrescriptions)),
            )
          else
            ...prescriptions.map(
              (rx) => Card(
                child: ListTile(
                  leading: Icon(
                    Icons.description,
                    color: rx.isActive
                        ? AppColors.successGreen
                        : AppColors.neutralGray,
                  ),
                  title: Text(rx.symptoms ?? l10n.prescription),
                  subtitle: Text(
                    l10n.statusMedicines(rx.status, rx.medications.length),
                  ),
                  trailing: Text(
                    _formatDate(rx.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
        ],
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

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Adherence Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AdherenceTab extends StatelessWidget {
  final PatientDetails details;
  const _AdherenceTab({required this.details});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeline = details.adherenceTimeline;

    if (timeline.isEmpty) {
      return Center(child: Text(l10n.noAdherenceData));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyAdherenceLast30,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),

          // Simple bar chart representation
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: timeline.map((point) {
                final pct = point.percentage;
                return Expanded(
                  child: Tooltip(
                    message: '${point.date}: ${pct.toStringAsFixed(0)}%',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: (pct / 100) * 180 + 2,
                      decoration: BoxDecoration(
                        color: _barColor(pct),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.successGreen, label: '≥90%'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.warningOrange, label: '70-89%'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.alertRed, label: '<70%'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Timeline list
          Text(
            l10n.dailyBreakdown,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...timeline.reversed.take(14).map(
            (point) => ListTile(
              dense: true,
              leading: Icon(
                Icons.circle,
                size: 12,
                color: _barColor(point.percentage),
              ),
              title: Text(point.date),
              trailing: Text(
                '${point.percentage.toStringAsFixed(0)}% (${point.takenDoses}/${point.totalDoses})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct >= 90) return AppColors.successGreen;
    if (pct >= 70) return AppColors.warningOrange;
    return AppColors.alertRed;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Notes Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _NotesTab extends StatelessWidget {
  final String patientId;
  final TextEditingController noteController;
  const _NotesTab({required this.patientId, required this.noteController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DoctorDashboardProvider>();

    return Column(
      children: [
        // Add note input
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: l10n.addNoteHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                onPressed: () async {
                  final content = noteController.text.trim();
                  if (content.isEmpty) return;
                  final success = await provider.createNote(patientId, content);
                  if (success) noteController.clear();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Notes list
        Expanded(
          child: provider.notesLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.doctorNotes.isEmpty
                  ? Center(child: Text(l10n.noNotesYet))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: provider.doctorNotes.length,
                      itemBuilder: (context, index) {
                        final note = provider.doctorNotes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      note.formattedDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () =>
                                              _showEditDialog(context, provider, note),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18,
                                              color: AppColors.alertRed),
                                          onPressed: () =>
                                              _showDeleteDialog(context, provider, note),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(note.content),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    DoctorDashboardProvider provider,
    DoctorNote note,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final editController = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editNote),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = editController.text.trim();
              if (content.isNotEmpty) {
                await provider.updateNote(note.id, content);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    DoctorDashboardProvider provider,
    DoctorNote note,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteNoteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await provider.deleteNote(note.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
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
            ElevatedButton(
              onPressed: _loadVitals,
              child: Text(l10n.retry),
            ),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._vitals.take(50).map(
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
                      ? const Icon(Icons.warning, color: AppColors.alertRed, size: 18)
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
