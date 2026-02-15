import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Family Feature tab – manage family connections and monitor linked patients.
/// Matches Figma tab: មុខងារគ្រួសារ
class PatientFamilyTab extends StatefulWidget {
  const PatientFamilyTab({super.key});

  @override
  State<PatientFamilyTab> createState() => _PatientFamilyTabState();
}

class _PatientFamilyTabState extends State<PatientFamilyTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ConnectionProvider>();
      provider.fetchCaregivers();
      provider.fetchConnectedPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.family),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/family/grace-period');
            },
            tooltip: l10n.gracePeriodSettings,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/family/history');
            },
            tooltip: l10n.history,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await connectionProvider.fetchCaregivers();
          await connectionProvider.fetchConnectedPatients();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Caregivers section
              Text(
                l10n.myCaregivers,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (connectionProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (connectionProvider.caregivers.isEmpty &&
                  connectionProvider.connectedPatients.isEmpty)
                _buildEmptyState(context)
              else ...[
                // Caregivers
                if (connectionProvider.caregivers.isNotEmpty)
                  ...connectionProvider.caregivers.map<Widget>(
                    (conn) => _buildFamilyMemberCard(context, conn),
                  ),

                // Patients I'm monitoring
                if (connectionProvider.connectedPatients.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.patientsIMonitor,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...connectionProvider.connectedPatients.map<Widget>(
                    (conn) => _buildPatientCard(context, conn),
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xl),

              // Connect button
              Center(
                child: PrimaryButton(
                  text: l10n.connectNow,
                  icon: Icons.link,
                  onPressed: () {
                    Navigator.pushNamed(context, '/family/connect');
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // View all connections
              Center(
                child: PrimaryButton(
                  text: l10n.viewAllConnections,
                  icon: Icons.people_outline,
                  isOutlined: true,
                  onPressed: () {
                    Navigator.pushNamed(context, '/family/access-list');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.family_restroom,
                size: 64, color: AppColors.neutral300),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noConnections,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.connectWithFamily,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(BuildContext context, Connection connection) {
    final l10n = AppLocalizations.of(context)!;
    final name = connection.getOtherUserName(connection.recipientId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: connection.status.name == 'accepted'
            ? () {
                Navigator.pushNamed(context, '/family/access-list');
              }
            : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Icon(Icons.person,
                  color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.unknown : name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    Connection.permissionLevelToDisplay(
                        connection.permissionLevel),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
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
                color: connection.status.name == 'accepted'
                    ? AppColors.statusSuccess.withValues(alpha: 0.1)
                    : AppColors.statusWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                connection.status.name == 'accepted' ? l10n.activeStatus : l10n.waitingStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: connection.status.name == 'accepted'
                      ? AppColors.statusSuccess
                      : AppColors.statusWarning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Connection connection) {
    final l10n = AppLocalizations.of(context)!;
    final name = connection.getOtherUserName(connection.initiatorId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: connection.status.name == 'accepted'
            ? () {
                Navigator.pushNamed(
                  context,
                  '/family/caregiver-dashboard',
                  arguments: {'connection': connection},
                );
              }
            : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  AppColors.successGreen.withValues(alpha: 0.1),
              child: Icon(Icons.favorite,
                  color: AppColors.successGreen, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.patient : name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    Connection.permissionLevelToDisplay(
                        connection.permissionLevel),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (connection.status.name == 'accepted')
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
