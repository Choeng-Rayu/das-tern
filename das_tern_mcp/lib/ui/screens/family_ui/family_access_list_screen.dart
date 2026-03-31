import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../models/enums_model/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../utils/app_router.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ConnectionProvider>();
      provider.fetchCaregivers();
      provider.fetchConnectedPatients();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          // Blue gradient header
          AppPageHeader(
            title: l10n.myFamily,
            showBackButton: false,
            showLogo: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.familyHistory);
                },
                tooltip: l10n.connectionHistory,
              ),
              const LanguageSwitcherButton(lightBackground: false),
              const SizedBox(width: 8),
            ],
            extraContent: [
              // Search bar
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: AppSpacing.md,
                    ),
                    filled: false,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Tab bar inside header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: l10n.caregiversTab),
                    Tab(text: l10n.patientsTab),
                  ],
                ),
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CaregiversList(searchQuery: _searchQuery),
                _PatientsMonitoredList(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.familyConnect);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newConnection),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
    );
  }
}

/// Tab 1: My caregivers (shown to patient)
class _CaregiversList extends StatelessWidget {
  final String searchQuery;

  const _CaregiversList({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = _filterConnections(
          provider.caregivers,
          searchQuery,
          useInitiator: true,
        );

        if (provider.caregivers.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.people_outline,
            title: l10n.noCaregiversYet,
            subtitle: l10n.shareQrToAllowFamily,
          );
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.search_off,
            title: l10n.noResultsFound,
            subtitle: '',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchCaregivers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _CaregiverCard(connection: filtered[index]);
            },
          ),
        );
      },
    );
  }
}

/// Tab 2: Patients I'm monitoring (shown to caregiver)
class _PatientsMonitoredList extends StatelessWidget {
  final String searchQuery;

  const _PatientsMonitoredList({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = _filterConnections(
          provider.connectedPatients,
          searchQuery,
          useInitiator: false,
        );

        if (provider.connectedPatients.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.favorite_border,
            title: l10n.notMonitoringPatients,
            subtitle: l10n.scanQrToStartMonitoring,
          );
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.search_off,
            title: l10n.noResultsFound,
            subtitle: '',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchConnectedPatients(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _PatientCard(connection: filtered[index]);
            },
          ),
        );
      },
    );
  }
}

List<Connection> _filterConnections(
  List<Connection> connections,
  String query, {
  required bool useInitiator,
}) {
  if (query.isEmpty) return connections;
  return connections.where((c) {
    final person = _getOtherPerson(c, preferPatient: !useInitiator);
    final name = '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'
        .trim();
    final fullName = person['fullName']?.toString() ?? '';
    return name.toLowerCase().contains(query) ||
        fullName.toLowerCase().contains(query);
  }).toList();
}

/// Determines the "other" person in a connection.
/// For the Caregivers tab (preferPatient=false): returns the non-PATIENT side.
/// For the Patients tab (preferPatient=true): returns the PATIENT side.
/// Falls back to role-based detection, then to recipient.
Map<String, dynamic> _getOtherPerson(
  Connection c, {
  required bool preferPatient,
}) {
  final initiator = c.initiator ?? {};
  final recipient = c.recipient ?? {};
  final initiatorRole = initiator['role']?.toString() ?? '';
  final recipientRole = recipient['role']?.toString() ?? '';

  if (preferPatient) {
    // We want the patient side
    if (recipientRole == 'PATIENT') return recipient;
    if (initiatorRole == 'PATIENT') return initiator;
    return recipient; // fallback
  } else {
    // We want the caregiver / non-patient side
    if (initiatorRole == 'FAMILY_MEMBER' || initiatorRole == 'DOCTOR') {
      return initiator;
    }
    if (recipientRole == 'FAMILY_MEMBER' || recipientRole == 'DOCTOR') {
      return recipient;
    }
    return initiator; // fallback
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    ),
  );
}

String _getInitials(Map<String, dynamic> person) {
  final first = (person['firstName'] ?? '') as String;
  final last = (person['lastName'] ?? '') as String;
  final fullName = (person['fullName'] ?? '') as String;

  if (first.isNotEmpty && last.isNotEmpty) {
    return '${first[0]}${last[0]}'.toUpperCase();
  }
  if (fullName.isNotEmpty) {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
  return '?';
}

class _CaregiverCard extends StatelessWidget {
  final Connection connection;

  const _CaregiverCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final caregiver = _getOtherPerson(connection, preferPatient: false);
    final name =
        '${caregiver['firstName'] ?? ''} ${caregiver['lastName'] ?? ''}'.trim();
    final initials = _getInitials(caregiver);
    final currentUserId = context.read<AuthProvider>().user?['id']?.toString();
    final canRespondPending =
        currentUserId != null &&
        connection.status == ConnectionStatus.pending &&
        connection.recipientId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBlue.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? l10n.caregiverLabel : name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Connection.permissionLevelToDisplay(
                          connection.permissionLevel,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _AlertsToggle(connection: connection),
                _buildConnectionStatusBadge(context, connection),
              ],
            ),
            if (canRespondPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _handlePendingAction(context, accept: false),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l10n.rejectConnection),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertRed,
                        side: const BorderSide(color: AppColors.alertRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handlePendingAction(context, accept: true),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.approveConnection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePendingAction(
    BuildContext context, {
    required bool accept,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ConnectionProvider>();
    final success = accept
        ? await provider.acceptConnection(connection.id, {
            'permissionLevel': 'ALLOWED',
          })
        : await provider.revokeConnection(connection.id);

    if (!context.mounted) return;

    await provider.fetchCaregivers();
    await provider.fetchConnectedPatients();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (accept ? l10n.connectionApproved : l10n.connectionRejected)
              : (provider.error ?? l10n.failedToConnect),
        ),
        backgroundColor: success
            ? (accept ? AppColors.successGreen : AppColors.textSecondary)
            : AppColors.alertRed,
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Connection connection;

  const _PatientCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final patient = _getOtherPerson(connection, preferPatient: true);
    final name = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
        .trim();
    final initials = _getInitials(patient);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: connection.status == ConnectionStatus.accepted
            ? () {
                Navigator.pushNamed(
                  context,
                  AppRouter.familyPatientDetail,
                  arguments: {'connection': connection},
                );
              }
            : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.successGreen.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Connection.permissionLevelToDisplay(
                      connection.permissionLevel,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildConnectionStatusBadge(context, connection),
            if (connection.status == ConnectionStatus.accepted)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(Icons.chevron_right, color: AppColors.neutral400),
              ),
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
        context.read<ConnectionProvider>().toggleAlerts(connection.id, value);
      },
      activeTrackColor: AppColors.primaryBlue,
    );
  }
}

Widget _buildConnectionStatusBadge(
  BuildContext context,
  Connection connection,
) {
  final l10n = AppLocalizations.of(context)!;
  final Color color;
  final String label;

  switch (connection.status) {
    case ConnectionStatus.pending:
      color = AppColors.warningOrange;
      label = l10n.pending;
    case ConnectionStatus.accepted:
      color = AppColors.successGreen;
      label = l10n.active;
    case ConnectionStatus.revoked:
      color = AppColors.alertRed;
      label = l10n.statusRevoked;
  }

  return StatusBadge(label: label, color: color, borderRadius: 12);
}
