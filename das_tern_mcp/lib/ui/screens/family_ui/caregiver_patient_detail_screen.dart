import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../models/enums_model/enums.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Detail screen for a caregiver viewing a specific patient.
/// Shows patient info, access level, alerts toggle, and today's dose schedule.
class CaregiverPatientDetailScreen extends StatefulWidget {
  const CaregiverPatientDetailScreen({super.key});

  @override
  State<CaregiverPatientDetailScreen> createState() =>
      _CaregiverPatientDetailScreenState();
}

class _CaregiverPatientDetailScreenState
    extends State<CaregiverPatientDetailScreen> {
  Connection? _connection;
  Map<String, dynamic>? _doseData;
  Map<String, dynamic> _patientData = {};
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
        _resolvePatientData();
        _loadDoses();
      }
    }
  }

  void _resolvePatientData() {
    if (_connection == null) return;
    final recipient = _connection!.recipient;
    final initiator = _connection!.initiator;

    // Determine which side is the patient by checking the role field
    if (recipient != null && recipient['role'] == 'PATIENT') {
      _patientData = Map<String, dynamic>.from(recipient);
    } else if (initiator != null && initiator['role'] == 'PATIENT') {
      _patientData = Map<String, dynamic>.from(initiator);
    } else {
      // Fallback: if roles not set, assume recipient is patient
      _patientData = Map<String, dynamic>.from(recipient ?? initiator ?? {});
    }
  }

  String? _getPatientId() {
    if (_patientData['id'] != null) return _patientData['id'] as String;
    return _connection?.recipientId;
  }

  Future<void> _loadDoses() async {
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() {
        _error = 'Could not determine patient';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = context.read<ConnectionProvider>();
      final data = await provider.getPatientDoses(patientId);
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

  String _getPatientName() {
    final fullName = _patientData['fullName'] as String?;
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final first = _patientData['firstName'] ?? '';
    final last = _patientData['lastName'] ?? '';
    final name = '$first $last'.trim();
    return name;
  }

  String _getInitials() {
    final name = _getPatientName();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  int? _calculateAge() {
    final dob = _patientData['dateOfBirth'] ?? _patientData['dob'];
    if (dob == null) return null;
    try {
      final birthDate = DateTime.parse(dob as String);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  bool get _hasMissedDoses {
    final doses =
        (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return doses.any((d) => d['status'] == 'MISSED');
  }

  bool get _canNudge {
    if (_connection == null) return false;
    // View+Remind (selected) or View+Manage (allowed)
    return _connection!.permissionLevel == PermissionLevel.selected ||
        _connection!.permissionLevel == PermissionLevel.allowed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_connection == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.patient),
          actions: const [LanguageSwitcherButton(lightBackground: true)],
        ),
        body: Center(child: Text(l10n.connectionNotFound)),
      );
    }

    final patientName = _getPatientName();

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName.isEmpty ? l10n.patient : patientName),
        centerTitle: true,
        actions: [
          const LanguageSwitcherButton(lightBackground: true),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'disconnect') {
                _showDisconnectDialog(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'disconnect',
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
          ? _buildErrorState(context)
          : RefreshIndicator(
              onRefresh: _loadDoses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoCard(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildAccessLevelCard(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDoseScheduleSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
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
              onPressed: _loadDoses,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _getPatientName();
    final initials = _getInitials();
    final gender = _patientData['gender'] as String?;
    final age = _calculateAge();
    final phone =
        _patientData['phoneNumber'] ??
        _patientData['phone'] ??
        _patientData['contactNumber'];

    final doses =
        (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final taken = _doseData?['taken'] as int? ?? 0;
    final missed = _doseData?['missed'] as int? ?? 0;
    final total = _doseData?['total'] as int? ?? 0;
    final pending = total - taken - missed;

    return AppCard(
      child: Column(
        children: [
          // Avatar + name + status
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.successGreen.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
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
                          decoration: BoxDecoration(
                            color: _hasMissedDoses
                                ? AppColors.alertRed
                                : AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _hasMissedDoses
                              ? l10n.missedDosesSection
                              : l10n.connectionConnected,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _hasMissedDoses
                                    ? AppColors.alertRed
                                    : AppColors.successGreen,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Patient details rows
          if (gender != null)
            _buildInfoRow(context, Icons.person_outline, l10n.gender, gender),
          if (age != null)
            _buildInfoRow(
              context,
              Icons.cake_outlined,
              l10n.age,
              '$age ${l10n.yearsUnit}',
            ),
          if (phone != null)
            _buildInfoRow(
              context,
              Icons.phone_outlined,
              l10n.phone,
              phone.toString(),
            ),

          // Dose status dots
          if (doses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildDotStat(
                  context,
                  taken,
                  AppColors.successGreen,
                  l10n.taken,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildDotStat(context, missed, AppColors.alertRed, l10n.missed),
                const SizedBox(width: AppSpacing.md),
                _buildDotStat(
                  context,
                  pending > 0 ? pending : 0,
                  AppColors.neutral400,
                  l10n.pending,
                ),
              ],
            ),
          ],

          // Nudge button
          if (_canNudge && _hasMissedDoses) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendNudge(context, null),
                icon: const Icon(Icons.notifications_active, size: 18),
                label: Text(l10n.sendNudge),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warningOrange,
                  side: const BorderSide(color: AppColors.warningOrange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDotStat(
    BuildContext context,
    int count,
    Color color,
    String label,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessLevelCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
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
          // Alerts toggle
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

  Widget _buildDoseScheduleSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doses =
        (_doseData?['doses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${_monthName(now.month)}-${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.todayMedicationSchedule,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              dateStr,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (doses.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const Icon(
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
          )
        else
          ...doses.map((dose) => _buildMedicineCard(context, dose)),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, Map<String, dynamic> dose) {
    final l10n = AppLocalizations.of(context)!;
    final name = dose['medicationName'] ?? l10n.unknown;
    final status = dose['status'] ?? 'DUE';
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

    final statusInfo = _doseStatusInfo(l10n, status);
    final isMissed = status == 'MISSED';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: statusInfo.color,
                    size: 20,
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
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: statusInfo.label,
                  color: statusInfo.color,
                  borderRadius: 12,
                ),
              ],
            ),
            if (isMissed && _canNudge) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _sendNudge(context, dose),
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

  _DoseStatusInfo _doseStatusInfo(AppLocalizations l10n, String status) {
    switch (status) {
      case 'TAKEN_ON_TIME':
      case 'TAKEN':
      case 'TAKEN_LATE':
        return _DoseStatusInfo(AppColors.successGreen, l10n.taken);
      case 'MISSED':
        return _DoseStatusInfo(AppColors.alertRed, l10n.missed);
      case 'SKIPPED':
        return _DoseStatusInfo(AppColors.warningOrange, l10n.skipped);
      default:
        return _DoseStatusInfo(AppColors.primaryBlue, l10n.pending);
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _sendNudge(
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

  void _showDisconnectDialog(BuildContext context) {
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

class _DoseStatusInfo {
  final Color color;
  final String label;
  const _DoseStatusInfo(this.color, this.label);
}
