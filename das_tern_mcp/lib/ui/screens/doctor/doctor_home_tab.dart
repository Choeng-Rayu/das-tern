import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Doctor home tab – overview dashboard with real API data.
class DoctorHomeTab extends StatefulWidget {
  final void Function(int tabIndex)? onSwitchTab;
  const DoctorHomeTab({super.key, this.onSwitchTab});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DoctorDashboardProvider>();
      provider.fetchDashboardOverview();
      provider.fetchPendingConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DoctorDashboardProvider>();
    final user = auth.user;
    final overview = dashboard.dashboardOverview;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await dashboard.fetchDashboardOverview();
            await dashboard.fetchPendingConnections();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${user?['fullName'] ?? user?['firstName'] ?? 'Doctor'}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: const Icon(Icons.medical_services,
                          color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Loading indicator
                if (dashboard.dashboardLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ))
                else ...[
                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        label: 'Total Patients',
                        value: '${overview?.totalPatients ?? 0}',
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                        icon: Icons.warning_amber,
                        label: 'Need Attention',
                        value: '${overview?.patientsNeedingAttention ?? 0}',
                        color: AppColors.alertRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.pending_actions,
                        label: 'Pending Requests',
                        value: '${overview?.pendingRequests ?? dashboard.pendingConnections.length}',
                        color: AppColors.warningOrange,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                        icon: Icons.notifications_active,
                        label: 'Today Alerts',
                        value: '${overview?.todayAlerts.length ?? 0}',
                        color: AppColors.nightPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Today's Alerts
                  if (overview?.todayAlerts.isNotEmpty ?? false) ...[
                    Text(
                      'Critical Alerts',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...(overview?.todayAlerts ?? []).map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        color: alert.type == 'CRITICAL'
                            ? AppColors.alertRed.withValues(alpha: 0.05)
                            : AppColors.warningOrange.withValues(alpha: 0.05),
                        child: ListTile(
                          leading: Icon(
                            alert.type == 'CRITICAL'
                                ? Icons.error
                                : Icons.warning,
                            color: alert.type == 'CRITICAL'
                                ? AppColors.alertRed
                                : AppColors.warningOrange,
                          ),
                          title: Text(alert.patientName),
                          subtitle: Text(
                            '${alert.consecutiveMissed} consecutive missed doses',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/doctor/patient-detail',
                              arguments: {'patientId': alert.patientId},
                            );
                          },
                        ),
                      ),
                    )),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Pending Requests
                  if (dashboard.pendingConnections.isNotEmpty) ...[
                    Text(
                      'Pending Connection Requests',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...dashboard.pendingConnections.map((conn) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.warningOrange.withValues(alpha: 0.1),
                                child: const Icon(Icons.person_add,
                                    color: AppColors.warningOrange),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conn.patientName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      conn.initiator?.phoneNumber ?? 'Connection request',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: AppColors.successGreen),
                                onPressed: () async {
                                  await dashboard.acceptConnection(conn.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: AppColors.alertRed),
                                onPressed: () async {
                                  await dashboard.rejectConnection(conn.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.description,
                          label: 'New Prescription',
                          onTap: () {
                            widget.onSwitchTab?.call(2);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.search,
                          label: 'Find Patient',
                          onTap: () {
                            widget.onSwitchTab?.call(1);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(label, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
