import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../providers/connection_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../utils/app_router.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';

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
  Map<String, dynamic>? _doseData;
  bool _isLoading = true;
  String? _error;

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
    if (_connection == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Determine the patient ID from the connection
      final patientId = _getPatientId();
      if (patientId == null) {
        setState(() {
          _error = 'Could not determine patient';
          _isLoading = false;
        });
        return;
      }
      final apiService = context.read<ConnectionProvider>();
      final data = await apiService.getPatientDoses(patientId);
      if (mounted) {
        setState(() {
          _doseData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String? _getPatientId() {
    if (_connection == null) return null;
    // In getCaregivers(), the caregiver is the initiator and patient is the recipient
    // In getConnectedPatients(), the caregiver is initiator, patient is recipient
    final patientFromRecipient = _connection!.recipient;
    final patientFromInitiator = _connection!.initiator;

    // The patient is whoever is NOT the current caregiver
    // We determine by checking whose role includes patient context
    if (patientFromRecipient != null && patientFromRecipient['id'] != null) {
      final recipientRole = patientFromRecipient['role'] as String? ?? '';
      if (recipientRole == 'PATIENT') {
        return patientFromRecipient['id'] as String;
      }
    }
    if (patientFromInitiator != null && patientFromInitiator['id'] != null) {
      final initiatorRole = patientFromInitiator['role'] as String? ?? '';
      if (initiatorRole == 'PATIENT') {
        return patientFromInitiator['id'] as String;
      }
    }
    // Fall back to recipientId
    return _connection!.recipientId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_connection == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboard),
          actions: const [LanguageSwitcherButton(lightBackground: true)],
        ),
        body: Center(child: Text(l10n.connectionNotFound)),
      );
    }

    final patient = _connection!.recipient ?? _connection!.initiator ?? {};
    final patientName =
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName.isEmpty ? l10n.dashboard : patientName),
        centerTitle: true,
        actions: [
          const LanguageSwitcherButton(lightBackground: true),
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
                    const Icon(
                      Icons.link_off,
                      color: AppColors.alertRed,
                      size: 20,
                    ),
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
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.alertRed,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _loadPatientData,
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPatientData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium / trial status banner
                    _buildPremiumBanner(context),

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

  /// Returns a banner widget based on the patient's subscription tier.
  /// - FREEMIUM (no trial): orange warning with upgrade + optional claim-trial CTA.
  /// - FREEMIUM on active trial: green informational with days remaining.
  /// - PREMIUM / FAMILY_PREMIUM: no banner (returns empty SizedBox).
  Widget _buildPremiumBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = context.watch<SubscriptionProvider>();

    // Active premium — no banner needed
    if (sub.isPremium && !sub.isOnTrial) {
      return const SizedBox.shrink();
    }

    // On active trial — show a calm green informational banner
    if (sub.isOnTrial) {
      final days = sub.trialDaysRemaining;
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: AppColors.successGreen,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.premiumTrialActive,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                    ),
                  ),
                  Text(
                    l10n.trialDaysRemainingBanner(days),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // FREEMIUM — show upgrade CTA banner
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.warningOrange,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.premiumFeature,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.familyAlertsRequirePremium,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRouter.subscriptionUpgrade,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningOrange,
                    side: const BorderSide(color: AppColors.warningOrange),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.upgradeToPremiumForFamilyAlerts),
                ),
              ),
              if (sub.canClaimTrial) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.subscriptionUpgrade,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.claimFreeTrial),
                  ),
                ),
              ],
            ],
          ),
        ],
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
            child: const Icon(
              Icons.person,
              size: 28,
              color: AppColors.primaryBlue,
            ),
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
                  context.read<ConnectionProvider>().toggleAlerts(
                    _connection!.id,
                    value,
                  );
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
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryBlue,
            size: 20,
          ),
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
                    _connection!.permissionLevel,
                  ),
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
    final doses =
        (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (doses.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 40,
                  color: AppColors.neutral300,
                ),
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

    final taken = _doseData?['taken'] as int? ?? 0;
    final total = _doseData?['total'] as int? ?? 0;
    final missed = _doseData?['missed'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Row(
          children: [
            _buildStatChip(
              context,
              '$taken/$total',
              l10n.taken,
              AppColors.successGreen,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildStatChip(context, '$missed', l10n.missed, AppColors.alertRed),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...doses.map((dose) => _buildDoseCard(context, dose)),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
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
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedDosesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doses =
        (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final missedDoses = doses.where((d) => d['status'] == 'MISSED').toList();
    final canNudge = _connection!.permissionLevel.index >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber,
              color: AppColors.alertRed,
              size: 20,
            ),
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
        if (missedDoses.isEmpty)
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
          )
        else
          ...missedDoses.map(
            (dose) => _buildMissedDoseCard(context, dose, canNudge),
          ),
      ],
    );
  }

  Widget _buildMissedDoseCard(
    BuildContext context,
    Map<String, dynamic> dose,
    bool canNudge,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final name = dose['medicationName'] ?? l10n.unknown;
    final rawTime = dose['scheduledTime'];
    String timeStr = '';
    if (rawTime != null) {
      try {
        final dt = DateTime.parse(rawTime as String).toLocal();
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        timeStr = rawTime.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.alertRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.missed,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.alertRed,
                    ),
                  ),
                ),
              ],
            ),
            if (canNudge) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _sendNudgeForDose(context, dose),
                  icon: const Icon(Icons.notifications_active, size: 16),
                  label: Text(l10n.sendNudge),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningOrange,
                    side: const BorderSide(color: AppColors.warningOrange),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNudgeSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.notifications_active,
            size: 32,
            color: AppColors.warningOrange,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sendNudge,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.nudgeRemindPatient,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
    return _sendNudgeForDose(context, null);
  }

  Future<void> _sendNudgeForDose(
    BuildContext context,
    Map<String, dynamic>? dose,
  ) async {
    if (_connection == null) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ConnectionProvider>();
    final patientId = _getPatientId() ?? _connection!.recipientId;
    final doseId = _resolveDoseIdForNudge(dose);

    if (doseId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.noPendingDoses),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }

    final success = await provider.sendNudge(patientId, doseId);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.nudgeSentSuccess
                : (provider.error ?? l10n.nudgeSentFailed),
          ),
          backgroundColor: success
              ? AppColors.successGreen
              : AppColors.alertRed,
        ),
      );
    }
  }

  String? _resolveDoseIdForNudge(Map<String, dynamic>? selectedDose) {
    final selectedId = selectedDose?['id']?.toString().trim();
    if (selectedId != null && selectedId.isNotEmpty) {
      return selectedId;
    }

    final doses = (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final d in doses) {
      final status = d['status']?.toString();
      final id = d['id']?.toString().trim();
      if (id != null && id.isNotEmpty && (status == 'MISSED' || status == 'DUE')) {
        return id;
      }
    }

    for (final d in doses) {
      final id = d['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  void _showRevokeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disconnectDialogTitle),
        content: Text(l10n.disconnectDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ConnectionProvider>().revokeConnection(
                _connection!.id,
              );
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
