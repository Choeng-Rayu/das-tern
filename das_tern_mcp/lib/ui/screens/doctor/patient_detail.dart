import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Patient detail screen for doctor showing patient info and prescription history
class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final PatientDetail patient;
  final List<PrescriptionSummary> prescriptions;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patient,
    required this.prescriptions,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.patient.name), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Profile Card
            _PatientProfileCard(patient: widget.patient, isDark: isDark),
            const SizedBox(height: AppSpacing.lg),

            // Tabs for Overview / Prescriptions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DefaultTabController(
                length: 2,
                initialIndex: _selectedTabIndex,
                child: Column(
                  children: [
                    TabBar(
                      onTap: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                      tabs: [
                        Tab(text: l10n.overview),
                        Tab(text: l10n.prescriptionHistory),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        children: [
                          // Overview Tab
                          _PatientOverviewTab(
                            patient: widget.patient,
                            isDark: isDark,
                            l10n: l10n,
                          ),
                          // Prescriptions Tab
                          _PrescriptionsTab(
                            prescriptions: widget.prescriptions,
                            isDark: isDark,
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Patient profile card showing basic information
class _PatientProfileCard extends StatelessWidget {
  final PatientDetail patient;
  final bool isDark;

  const _PatientProfileCard({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (patient.isMedicationAdherent
                                    ? AppColors.successGreen
                                    : AppColors.alertRed)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        patient.isMedicationAdherent
                            ? 'Taking Meds'
                            : 'Not Taking',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: patient.isMedicationAdherent
                              ? AppColors.successGreen
                              : AppColors.alertRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Info Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              _InfoTile(
                label: 'Age',
                value: patient.age.toString(),
                isDark: isDark,
              ),
              _InfoTile(label: 'Gender', value: patient.gender, isDark: isDark),
              _InfoTile(
                label: 'Blood Type',
                value: patient.bloodType,
                isDark: isDark,
              ),
              _InfoTile(label: 'Contact', value: patient.phone, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

/// Information tile for patient details
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overview tab showing patient health summary
class _PatientOverviewTab extends StatelessWidget {
  final PatientDetail patient;
  final bool isDark;
  final AppLocalizations l10n;

  const _PatientOverviewTab({
    required this.patient,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symptoms Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symptoms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    patient.symptoms,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Adherence Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication Adherence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: patient.adherenceRate / 100,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      patient.adherenceRate >= 80
                          ? AppColors.successGreen
                          : patient.adherenceRate >= 50
                          ? AppColors.warningOrange
                          : AppColors.alertRed,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${patient.adherenceRate.toStringAsFixed(1)}% adherence rate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prescriptions tab showing list of prescriptions
class _PrescriptionsTab extends StatelessWidget {
  final List<PrescriptionSummary> prescriptions;
  final bool isDark;
  final AppLocalizations l10n;

  const _PrescriptionsTab({
    required this.prescriptions,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (prescriptions.isEmpty) {
      return Center(
        child: Text(
          l10n.noPrescriptions,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: prescriptions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _PrescriptionCard(
          prescription: prescriptions[index],
          isDark: isDark,
        );
      },
    );
  }
}

/// Prescription card showing summary
class _PrescriptionCard extends StatelessWidget {
  final PrescriptionSummary prescription;
  final bool isDark;

  const _PrescriptionCard({required this.prescription, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // Navigate to prescription detail
          // Navigator.pushNamed(context, '/doctor/prescription-detail', arguments: prescription.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prescription.date,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prescription.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${prescription.medicinesCount} medicines prescribed',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (prescription.diagnosis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Diagnosis: ${prescription.diagnosis}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Data models

class PatientDetail {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String bloodType;
  final String phone;
  final String symptoms;
  final double adherenceRate;
  final bool isMedicationAdherent;

  PatientDetail({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.phone,
    required this.symptoms,
    required this.adherenceRate,
    required this.isMedicationAdherent,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class PrescriptionSummary {
  final String id;
  final String date;
  final String status;
  final int medicinesCount;
  final String diagnosis;

  PrescriptionSummary({
    required this.id,
    required this.date,
    required this.status,
    required this.medicinesCount,
    required this.diagnosis,
  });
}
