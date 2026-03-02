import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/doctor_dashboard_model/patient_list_item.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Displays the list of patients who are currently receiving medication
/// (adherenceLevel == 'GREEN' or have active prescriptions).
class MedPatientListScreen extends StatefulWidget {
  const MedPatientListScreen({super.key});

  @override
  State<MedPatientListScreen> createState() => _MedPatientListScreenState();
}

class _MedPatientListScreenState extends State<MedPatientListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // fetch with GREEN filter so we only load compliant patients
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

    // filter: GREEN adherence = actively receiving medication
    final List<PatientListItem> displayed = provider.patients.where((p) {
      final matchesAdherence = p.adherenceLevel == 'GREEN';
      if (_search.isEmpty) return matchesAdherence;
      final q = _search.toLowerCase();
      return matchesAdherence &&
          (p.displayName.toLowerCase().contains(q) ||
              p.phoneNumber.contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.patientsInTreatment,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${displayed.length} ${l10n.personUnit}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Blue header bar that extends behind the search field
          Container(
            color: Colors.blue.shade400,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchPatients,
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchPatients(),
              child: provider.patientListLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayed.isEmpty
                  ? _EmptyState(hasSearch: _search.isNotEmpty, l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: displayed.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _PatientCard(
                          patient: displayed[index],
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/doctor/patient-detail',
                            arguments: {'patientId': displayed[index].id},
                          ),
                          l10n: l10n,
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

// ─────────────────────────────────────────────
// Patient card widget
// ─────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final PatientListItem patient;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.successGreen.withValues(alpha: 0.12),
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.medication_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.activePrescriptions} ${l10n.prescriptions}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            patient.phoneNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _AdherenceBadge(level: patient.adherenceLevel),
                        const SizedBox(width: 8),
                        Text(
                          '${patient.adherencePercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Adherence badge (green only on this screen)
// ─────────────────────────────────────────────

class _AdherenceBadge extends StatelessWidget {
  final String level;
  const _AdherenceBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color bg;
    Color fg;
    String text;
    switch (level) {
      case 'GREEN':
        bg = AppColors.successGreen.withValues(alpha: 0.15);
        fg = AppColors.successGreen;
        text = l10n.adherenceGood;
      case 'YELLOW':
        bg = AppColors.warningOrange.withValues(alpha: 0.15);
        fg = AppColors.warningOrange;
        text = l10n.adherenceModerate;
      default:
        bg = AppColors.alertRed.withValues(alpha: 0.15);
        fg = AppColors.alertRed;
        text = l10n.adherencePoor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final AppLocalizations l10n;
  const _EmptyState({required this.hasSearch, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasSearch ? l10n.noPatientsFound : l10n.noReceivingPatientsHint,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
