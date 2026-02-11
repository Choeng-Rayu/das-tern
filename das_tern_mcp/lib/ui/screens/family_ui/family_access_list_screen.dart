import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/connection_model/connection.dart';
import '../../../models/enums_model/enums.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Shows the list of connected family members / caregivers.
/// Patient sees their caregivers; caregiver sees their patients.
class FamilyAccessListScreen extends StatefulWidget {
  const FamilyAccessListScreen({super.key});

  @override
  State<FamilyAccessListScreen> createState() => _FamilyAccessListScreenState();
}

class _FamilyAccessListScreenState extends State<FamilyAccessListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ConnectionProvider>();
      provider.fetchCaregivers();
      provider.fetchConnectedPatients();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('គ្រួសាររបស់ខ្ញុំ'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'អ្នកថែទាំ'),
            Tab(text: 'អ្នកជំងឺ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/family/history');
            },
            tooltip: 'ប្រវត្តិការតភ្ជាប់',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CaregiversList(),
          _PatientsMonitoredList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/family/connect');
        },
        icon: const Icon(Icons.add),
        label: const Text('ភ្ជាប់ថ្មី'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
    );
  }
}

/// Tab 1: My caregivers (shown to patient)
class _CaregiversList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.caregivers.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.people_outline,
            title: 'មិនទាន់មានអ្នកថែទាំ',
            subtitle:
                'ចែករំលែកកូដ QR ដើម្បីអនុញ្ញាតគ្រួសារ\nត្រួតពិនិត្យការទទួលទានថ្នាំ',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchCaregivers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.caregivers.length,
            itemBuilder: (context, index) {
              return _CaregiverCard(connection: provider.caregivers[index]);
            },
          ),
        );
      },
    );
  }
}

/// Tab 2: Patients I'm monitoring (shown to caregiver)
class _PatientsMonitoredList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.connectedPatients.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.favorite_border,
            title: 'មិនទាន់តាមដានអ្នកជំងឺ',
            subtitle: 'ស្កេនកូដ QR ពីអ្នកជំងឺដើម្បីចាប់ផ្តើម\nតាមដានការទទួលទានថ្នាំ',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchConnectedPatients(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.connectedPatients.length,
            itemBuilder: (context, index) {
              return _PatientCard(
                  connection: provider.connectedPatients[index]);
            },
          ),
        );
      },
    );
  }
}

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    ),
  );
}

class _CaregiverCard extends StatelessWidget {
  final Connection connection;

  const _CaregiverCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    // For a patient, the caregiver is the initiator
    final caregiver = connection.initiator ?? {};
    final name =
        '${caregiver['firstName'] ?? ''} ${caregiver['lastName'] ?? ''}'
            .trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.person,
                  color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Caregiver' : name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Connection.permissionLevelToDisplay(
                        connection.permissionLevel),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // Alerts toggle
            _AlertsToggle(connection: connection),
            // Status badge
            _StatusBadge(connection: connection),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Connection connection;

  const _PatientCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    // For a caregiver, the patient is the recipient
    final patient = connection.recipient ?? {};
    final name =
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: connection.status == ConnectionStatus.accepted
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
              radius: 22,
              backgroundColor:
                  AppColors.successGreen.withValues(alpha: 0.1),
              child: const Icon(Icons.favorite,
                  color: AppColors.successGreen, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Patient' : name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Connection.permissionLevelToDisplay(
                        connection.permissionLevel),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            _StatusBadge(connection: connection),
            if (connection.status == ConnectionStatus.accepted)
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

class _AlertsToggle extends StatelessWidget {
  final Connection connection;

  const _AlertsToggle({required this.connection});

  @override
  Widget build(BuildContext context) {
    if (connection.status != ConnectionStatus.accepted) {
      return const SizedBox.shrink();
    }

    return Switch(
      value: connection.alertsEnabled,
      onChanged: (value) {
        context
            .read<ConnectionProvider>()
            .toggleAlerts(connection.id, value);
      },
      activeTrackColor: AppColors.primaryBlue,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Connection connection;

  const _StatusBadge({required this.connection});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (connection.status) {
      case ConnectionStatus.pending:
        color = AppColors.warningOrange;
        label = 'រង់ចាំ';
        break;
      case ConnectionStatus.accepted:
        color = AppColors.successGreen;
        label = 'សកម្ម';
        break;
      case ConnectionStatus.revoked:
        color = AppColors.alertRed;
        label = 'ដកហូត';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
