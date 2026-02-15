import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Caregiver dashboard for monitoring a specific patient's medication.
/// Shows dose schedule, missed doses, and nudge functionality.
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  Connection? _connection;
  final List<Map<String, dynamic>> _doses = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_connection == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _connection = args?['connection'] as Connection?;
      if (_connection != null) {
        _loadPatientData();
      }
    }
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    // In a full impl, fetch the patient's dose schedule via API
    // For now, we'll show the connection info
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_connection == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboard)),
        body: Center(child: Text(l10n.connectionNotFound)),
      );
    }

    final patient = _connection!.recipient ?? {};
    final patientName =
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName.isEmpty ? l10n.dashboard : patientName),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'revoke') {
                _showRevokeDialog(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'revoke',
                child: Row(
                  children: [
                    const Icon(Icons.link_off, color: AppColors.alertRed, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.disconnectConnection),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatientData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient header
                    _buildPatientHeader(context, patientName),
                    const SizedBox(height: AppSpacing.lg),

                    // Permission info
                    _buildPermissionCard(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Dose overview
                    Text(
                      l10n.todayMedicationSchedule,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDoseOverview(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Missed doses section
                    _buildMissedDosesSection(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Nudge button (if permission allows)
                    if (_connection!.permissionLevel.index >= 2)
                      _buildNudgeSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientHeader(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.person,
                size: 28, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? l10n.patient : name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.connectionConnected,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.successGreen,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Alert toggle
          Column(
            children: [
              Switch(
                value: _connection!.alertsEnabled,
                onChanged: (value) {
                  context
                      .read<ConnectionProvider>()
                      .toggleAlerts(_connection!.id, value);
                },
                activeTrackColor: AppColors.primaryBlue,
              ),
              Text(
                l10n.notifications,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accessLevelTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  Connection.permissionLevelToDisplay(
                      _connection!.permissionLevel),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseOverview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_doses.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.medication_outlined,
                    size: 40, color: AppColors.neutral300),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.noMedicationData,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _doses.map((dose) {
        return _buildDoseCard(context, dose);
      }).toList(),
    );
  }

  Widget _buildDoseCard(BuildContext context, Map<String, dynamic> dose) {
    final l10n = AppLocalizations.of(context)!;
    final name = dose['medicationName'] ?? l10n.unknown;
    final status = dose['status'] ?? 'DUE';
    final time = dose['scheduledTime'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'TAKEN_ON_TIME':
        statusColor = AppColors.successGreen;
        statusLabel = l10n.taken;
        break;
      case 'MISSED':
        statusColor = AppColors.alertRed;
        statusLabel = l10n.missed;
        break;
      case 'SKIPPED':
        statusColor = AppColors.warningOrange;
        statusLabel = l10n.skipped;
        break;
      default:
        statusColor = AppColors.primaryBlue;
        statusLabel = l10n.pending;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(time,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedDosesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.alertRed, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.missedDosesSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.alertRed,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${l10n.noMissedDoses} \u2713',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNudgeSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.notifications_active,
              size: 32, color: AppColors.warningOrange),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sendNudge,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.nudgeRemindPatient,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: l10n.sendNudge,
            icon: Icons.send,
            onPressed: () => _sendNudge(context),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNudge(BuildContext context) async {
    if (_connection == null) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ConnectionProvider>();
    final success = await provider.sendNudge(
      _connection!.recipientId,
      null, // doseId - could pass specific dose
    );

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.nudgeSentSuccess : l10n.nudgeSentFailed,
          ),
          backgroundColor:
              success ? AppColors.successGreen : AppColors.alertRed,
        ),
      );
    }
  }

  void _showRevokeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disconnectDialogTitle),
        content: Text(
          l10n.disconnectDialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ConnectionProvider>()
                  .revokeConnection(_connection!.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: Text(l10n.disconnectButton),
          ),
        ],
      ),
    );
  }
}
