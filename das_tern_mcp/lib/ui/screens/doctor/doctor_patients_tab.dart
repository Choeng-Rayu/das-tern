import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Doctor patients tab – list of connected patients with adherence data.
class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorDashboardProvider>().fetchPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DoctorDashboardProvider>();

    return Scaffold(
      appBar: AppHeader(title: l10n.myPatients),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchPatients,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                provider.setSearchQuery(value);
              },
            ),
          ),

          // Adherence filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppSelectableChip(
                    label: l10n.all,
                    selected: provider.adherenceFilter == null,
                    onTap: () => provider.setAdherenceFilter(null),
                    variant: ChipVariant.outlined,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppSelectableChip(
                    label: l10n.adherenceGood,
                    selected: provider.adherenceFilter == 'GREEN',
                    selectedColor: AppColors.successGreen,
                    onTap: () => provider.setAdherenceFilter('GREEN'),
                    variant: ChipVariant.outlined,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppSelectableChip(
                    label: l10n.adherenceModerate,
                    selected: provider.adherenceFilter == 'YELLOW',
                    selectedColor: AppColors.warningOrange,
                    onTap: () => provider.setAdherenceFilter('YELLOW'),
                    variant: ChipVariant.outlined,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppSelectableChip(
                    label: l10n.adherencePoor,
                    selected: provider.adherenceFilter == 'RED',
                    selectedColor: AppColors.alertRed,
                    onTap: () => provider.setAdherenceFilter('RED'),
                    variant: ChipVariant.outlined,
                  ),
                ],
              ),
            ),
          ),

          // Patient list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchPatients(),
              child: provider.patientListLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.patients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.neutral300,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.noPatientsFound,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            (provider.searchQuery?.isNotEmpty ?? false)
                                ? l10n.tryDifferentSearch
                                : l10n.connectedPatientsAppearHere,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: provider.patients.length,
                      itemBuilder: (context, index) {
                        final patient = provider.patients[index];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        return _PatientListCard(
                          patient: patient,
                          isDark: isDark,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/doctor/patient-detail',
                              arguments: {'patientId': patient.id},
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient list card showing patient info, diagnosis, and medication status
class _PatientListCard extends StatelessWidget {
  final dynamic patient; // PatientListItem
  final bool isDark;
  final VoidCallback? onTap;

  const _PatientListCard({
    required this.patient,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        elevation: isDark ? 2 : 1,
        color: isDark ? Colors.grey[850] : Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Name Row with Avatar
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      patient.initials,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Patient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Diagnosis/Sickness (show active prescription count)
                        Text(
                          patient.activePrescriptions > 0
                              ? '${patient.activePrescriptions} ${patient.activePrescriptions == 1 ? l10n.prescription : l10n.prescriptions}'
                              : l10n.noPrescriptions,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Medication Status + Adherence Row
              Row(
                children: [
                  // Medication Status Badge (taken/not taken indicator)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getMedicationStatusColor(
                          patient.adherencePercentage,
                          isDark,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getMedicationStatusText(
                          patient.adherencePercentage,
                          l10n,
                        ),
                        style: TextStyle(
                          color: _getMedicationStatusColor(
                            patient.adherencePercentage,
                            isDark,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Adherence Percentage
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: _getMedicationStatusColor(
                            patient.adherencePercentage,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.adherencePercentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getMedicationStatusColor(
                                  patient.adherencePercentage,
                                  isDark,
                                ),
                              ),
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
    );
  }

  Color _getMedicationStatusColor(double adherencePercentage, bool isDark) {
    if (adherencePercentage >= 80) {
      return AppColors.successGreen;
    } else if (adherencePercentage >= 50) {
      return AppColors.warningOrange;
    } else {
      return AppColors.alertRed;
    }
  }

  String _getMedicationStatusText(
    double adherencePercentage,
    AppLocalizations l10n,
  ) {
    if (adherencePercentage >= 80) {
      return l10n.adherenceGood;
    } else if (adherencePercentage >= 50) {
      return l10n.adherenceModerate;
    } else {
      return l10n.adherencePoor;
    }
  }
}
