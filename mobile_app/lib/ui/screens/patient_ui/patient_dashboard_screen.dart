import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/prescription_provider.dart';
import '../../../providers/dose_event_provider_v2.dart';
import '../../widgets/time_group_section.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'create_medication_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await context.read<PrescriptionProvider>().loadPrescriptions();
    if (!mounted) return;
    await context.read<DoseEventProviderV2>().loadTodayDoseEvents();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prescriptionProvider = context.watch<PrescriptionProvider>();
    final doseEventProvider = context.watch<DoseEventProviderV2>();

    final daytimeDoses = doseEventProvider.getDoseEventsByTimeGroup('daytime');
    final nightDoses = doseEventProvider.getDoseEventsByTimeGroup('night');

    final progress = doseEventProvider.totalCount > 0
        ? doseEventProvider.completedCount / doseEventProvider.totalCount
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: prescriptionProvider.isLoading
            ? const LoadingWidget(message: 'Loading prescriptions...')
            : prescriptionProvider.error != null
                ? ErrorDisplayWidget(
                    message: prescriptionProvider.error!,
                    onRetry: _loadData,
                  )
                : ListView(
                    children: [
                      // Progress Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.todaySchedule,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${doseEventProvider.completedCount}/${doseEventProvider.totalCount} ${l10n.completed}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      // Daytime Section
                      if (daytimeDoses.isNotEmpty)
                        TimeGroupSection(
                          label: l10n.daytime,
                          color: const Color(0xFF2D5BFF),
                          children: daytimeDoses.map((doseEvent) {
                            return ListTile(
                              title: Text('Dose at ${doseEvent.scheduledTime.hour}:${doseEvent.scheduledTime.minute.toString().padLeft(2, '0')}'),
                              subtitle: Text('Status: ${doseEvent.status}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: () {
                                  if (doseEvent.id != null) {
                                    context.read<DoseEventProviderV2>().markDoseTaken(doseEvent.id!);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),

                      // Night Section
                      if (nightDoses.isNotEmpty)
                        TimeGroupSection(
                          label: l10n.night,
                          color: const Color(0xFF6B4AA3),
                          children: nightDoses.map((doseEvent) {
                            return ListTile(
                              title: Text('Dose at ${doseEvent.scheduledTime.hour}:${doseEvent.scheduledTime.minute.toString().padLeft(2, '0')}'),
                              subtitle: Text('Status: ${doseEvent.status}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: () {
                                  if (doseEvent.id != null) {
                                    context.read<DoseEventProviderV2>().markDoseTaken(doseEvent.id!);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),

                      // Empty State
                      if (daytimeDoses.isEmpty && nightDoses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No medications scheduled for today',
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMedicationScreen(),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
