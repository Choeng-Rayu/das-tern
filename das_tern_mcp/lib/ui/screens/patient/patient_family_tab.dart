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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().fetchConnections();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('មុខងារគ្រួសារ'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => connectionProvider.fetchConnections(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar (matches Figma: ស្វែងរកអ្នកជំងឺ)
              AppTextField(
                controller: _searchController,
                label: '',
                hint: 'ស្វែងរកអ្នកជំងឺ',
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Connected family members
              Text(
                'Family Members',
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
              else if (connectionProvider.acceptedConnections.isEmpty &&
                  connectionProvider.pendingConnections.isEmpty)
                _buildEmptyState(context)
              else ...[
                // Accepted connections
                ...connectionProvider.acceptedConnections.map<Widget>(
                  (conn) => _buildFamilyMemberCard(context, conn, true),
                ),
                // Pending connections
                if (connectionProvider.pendingConnections.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pending',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...connectionProvider.pendingConnections.map<Widget>(
                    (conn) => _buildFamilyMemberCard(context, conn, false),
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xl),

              // Connect button (matches Figma: ភ្ជាប់ពេលនេះ)
              Center(
                child: PrimaryButton(
                  text: 'ភ្ជាប់ពេលនេះ',
                  icon: Icons.link,
                  onPressed: () {
                    // TODO: Show connect dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connect feature coming soon'),
                      ),
                    );
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
              'Connect with family members\nto monitor their medication.',
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

  Widget _buildFamilyMemberCard(
    BuildContext context,
    Connection connection,
    bool isAccepted,
  ) {
    final patient = connection.patient ?? connection.doctor ?? {};
    final name = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
        .trim();
    final symptom = '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: isAccepted
            ? () {
                // TODO: Navigate to family member detail
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
                  if (symptom.isNotEmpty)
                    Text(
                      'រោគសញ្ញា: $symptom',
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
                color: isAccepted
                    ? AppColors.statusSuccess.withValues(alpha: 0.1)
                    : AppColors.statusWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAccepted ? 'ទទួលទានថ្នាំ' : 'មិនបានទទួលទានថ្នាំ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isAccepted
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
}
