import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

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
    final provider = context.watch<DoctorDashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
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
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: provider.adherenceFilter == null,
                    onTap: () => provider.setAdherenceFilter(null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Good',
                    selected: provider.adherenceFilter == 'GREEN',
                    color: AppColors.successGreen,
                    onTap: () => provider.setAdherenceFilter('GREEN'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Moderate',
                    selected: provider.adherenceFilter == 'YELLOW',
                    color: AppColors.warningOrange,
                    onTap: () => provider.setAdherenceFilter('YELLOW'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Poor',
                    selected: provider.adherenceFilter == 'RED',
                    color: AppColors.alertRed,
                    onTap: () => provider.setAdherenceFilter('RED'),
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
                              Icon(Icons.people_outline,
                                  size: 64, color: AppColors.neutral300),
                              const SizedBox(height: AppSpacing.md),
                              Text('No patients found',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                (provider.searchQuery?.isNotEmpty ?? false)
                                    ? 'Try a different search.'
                                    : 'Connected patients will appear here.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
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

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryBlue
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    patient.initials,
                                    style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(patient.displayName),
                                subtitle: Row(
                                  children: [
                                    _AdherenceBadge(level: patient.adherenceLevel),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '${patient.adherencePercentage.toStringAsFixed(0)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color:
                                                  AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/doctor/patient-detail',
                                    arguments: {'patientId': patient.id},
                                  );
                                },
                              ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AdherenceBadge extends StatelessWidget {
  final String level;
  const _AdherenceBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (level) {
      case 'GREEN':
        bgColor = AppColors.successGreen.withValues(alpha: 0.15);
        textColor = AppColors.successGreen;
        text = 'Good';
        break;
      case 'YELLOW':
        bgColor = AppColors.warningOrange.withValues(alpha: 0.15);
        textColor = AppColors.warningOrange;
        text = 'Moderate';
        break;
      case 'RED':
        bgColor = AppColors.alertRed.withValues(alpha: 0.15);
        textColor = AppColors.alertRed;
        text = 'Poor';
        break;
      default:
        bgColor = AppColors.neutral300.withValues(alpha: 0.15);
        textColor = AppColors.textSecondary;
        text = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
