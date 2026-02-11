import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    if (_connection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ផ្ទាំងត្រួតពិនិត្យ')),
        body: const Center(child: Text('Connection not found')),
      );
    }

    final patient = _connection!.recipient ?? {};
    final patientName =
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName.isEmpty ? 'ផ្ទាំងត្រួតពិនិត្យ' : patientName),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'revoke') {
                _showRevokeDialog(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'revoke',
                child: Row(
                  children: [
                    Icon(Icons.link_off, color: AppColors.alertRed, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('ផ្តាច់ការតភ្ជាប់'),
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
                      'តារាងថ្នាំថ្ងៃនេះ',
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
                  name.isEmpty ? 'Patient' : name,
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
                      'តភ្ជាប់រួចរាល់',
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
                'ការជូនដំណឹង',
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
                  'កម្រិតការចូលប្រើ',
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
                  'មិនមានទិន្នន័យថ្នាំ',
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
    final name = dose['medicationName'] ?? 'Unknown';
    final status = dose['status'] ?? 'DUE';
    final time = dose['scheduledTime'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'TAKEN_ON_TIME':
        statusColor = AppColors.successGreen;
        statusLabel = 'ទទួលទានថ្នាំ';
        break;
      case 'MISSED':
        statusColor = AppColors.alertRed;
        statusLabel = 'ខកខាន';
        break;
      case 'SKIPPED':
        statusColor = AppColors.warningOrange;
        statusLabel = 'រំលង';
        break;
      default:
        statusColor = AppColors.primaryBlue;
        statusLabel = 'កំពុងរង់ចាំ';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.alertRed, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'ថ្នាំខកខាន',
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
                'មិនមានថ្នាំខកខាន ✓',
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
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.notifications_active,
              size: 32, color: AppColors.warningOrange),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ផ្ញើការរំលឹក',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'រំលឹកអ្នកជំងឺពីការទទួលទានថ្នាំ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: 'ផ្ញើការរំលឹក',
            icon: Icons.send,
            onPressed: () => _sendNudge(context),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNudge(BuildContext context) async {
    if (_connection == null) return;

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
            success ? 'ការរំលឹកត្រូវបានផ្ញើ' : 'មិនអាចផ្ញើការរំលឹក',
          ),
          backgroundColor:
              success ? AppColors.successGreen : AppColors.alertRed,
        ),
      );
    }
  }

  void _showRevokeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ផ្តាច់ការតភ្ជាប់?'),
        content: const Text(
          'អ្នកនឹងមិនអាចមើលព័ត៌មានថ្នាំរបស់អ្នកជំងឺនេះទៀតទេ។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
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
            child: const Text('ផ្តាច់'),
          ),
        ],
      ),
    );
  }
}
