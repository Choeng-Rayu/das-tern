import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('មុខងារគ្រួសារ'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/family/grace-period');
            },
            tooltip: 'ការកំណត់ពេលវេលា',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/family/history');
            },
            tooltip: 'ប្រវត្តិ',
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
                'អ្នកថែទាំរបស់ខ្ញុំ',
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
                    'អ្នកជំងឺដែលខ្ញុំតាមដាន',
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
                  text: 'ភ្ជាប់ពេលនេះ',
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
                  text: 'មើលការតភ្ជាប់ទាំងអស់',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.family_restroom,
                size: 64, color: AppColors.neutral300),
            const SizedBox(height: AppSpacing.md),
            Text(
              'មិនមានដំណរភ្ជាប់',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ភ្ជាប់ជាមួយគ្រួសារដើម្បី\nត្រួតពិនិត្យការទទួលទានថ្នាំ',
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
                    name.isEmpty ? 'Unknown' : name,
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
                connection.status.name == 'accepted' ? 'សកម្ម' : 'រង់ចាំ',
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
                    name.isEmpty ? 'Patient' : name,
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
