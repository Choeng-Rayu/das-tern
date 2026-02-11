import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../models/doctor_dashboard_model/doctor_dashboard_models.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    final provider = context.watch<DoctorDashboardProvider>();
    final details = provider.selectedPatientDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          details?.patient.displayName ?? 'Patient',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Adherence'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: provider.detailsLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
              ? Center(
                  child: Text(
                    provider.error ?? 'Failed to load patient details',
                    style: TextStyle(color: AppColors.alertRed),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(details: details),
                    _AdherenceTab(details: details),
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
                              'Age: ${patient.age ?? 'N/A'} • ${patient.gender ?? 'N/A'}',
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
                  _MetricColumn(
                    label: 'Late',
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
            'Active Prescriptions (${prescriptions.where((p) => p.isActive).length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (prescriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('No prescriptions')),
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
                  title: Text(rx.symptoms ?? 'Prescription'),
                  subtitle: Text(
                    '${rx.status} • ${rx.medications.length} medicines',
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
    final timeline = details.adherenceTimeline;

    if (timeline.isEmpty) {
      return const Center(child: Text('No adherence data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Adherence (Last 30 Days)',
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
            'Daily Breakdown',
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
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
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
                  ? const Center(child: Text('No notes yet'))
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
    final editController = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = editController.text.trim();
              if (content.isNotEmpty) {
                await provider.updateNote(note.id, content);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
