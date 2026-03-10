import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/connection_model/connection.dart';
import '../../../../providers/connection_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/language_switcher.dart';

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
    final hasConnections =
        connectionProvider.caregivers.isNotEmpty ||
        connectionProvider.connectedPatients.isNotEmpty;

    return ColoredBox(
      color: AppColors.white,
      child: RefreshIndicator(
        onRefresh: () async {
          await connectionProvider.fetchCaregivers();
          await connectionProvider.fetchConnectedPatients();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Header with background ──
              _FamilyHeader(l10n: l10n),

              // ── Body content ──
              if (!connectionProvider.isLoading && !hasConnections)
                _FamilyIntroContent(l10n: l10n)
              else
                _FamilyConnectionsList(
                  connectionProvider: connectionProvider,
                  l10n: l10n,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: background image + doctor logo + language switcher + notification
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/backgroundHeader.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: logo + name + lang switcher + notification
                  Row(
                    children: [
                      // Doctor avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/doctorLogo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'ដាស់ទើន',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      // Language switcher
                      const LanguageSwitcherButton(),
                      const SizedBox(width: AppSpacing.sm),
                      // Notification bell
                      _buildNotificationBell(context),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                  ),

                  // Title
                  Text(
                    l10n.familyFunctionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/family/history');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          // Badge
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: AppColors.alertRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intro content (shown when no connections exist)
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyIntroContent extends StatelessWidget {
  const _FamilyIntroContent({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // ── Two illustration cards side by side ──
          Row(
            children: [
              Expanded(
                child: _buildIllustrationCard(
                  icon: Icons.family_restroom,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildIllustrationCard(
                  icon: Icons.notifications_active,
                  color: AppColors.warningOrange,
                  showPhone: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Description text ──
          Text(
            l10n.familyIntroDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Bullet points ──
          _buildBulletPoint('• ${l10n.familyBulletSender}'),
          const SizedBox(height: AppSpacing.xs),
          _buildBulletPoint('• ${l10n.familyBulletReceiver}'),

          const SizedBox(height: AppSpacing.md),

          // ── Footer description ──
          Text(
            l10n.familyIntroFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Start Using button (blue) ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/family/connect');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.startUsing,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Learn More button (outlined) ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/family/access-list');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.neutral300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
              ),
              child: Text(
                l10n.learnMore,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildIllustrationCard({
    required IconData icon,
    required Color color,
    bool showPhone = false,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Center(
        child: showPhone
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Sound waves left
                  Positioned(
                    left: 20,
                    child: Icon(
                      Icons.wifi,
                      color: color.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
                  // Phone with bell
                  Container(
                    width: 48,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  // Sound waves right
                  Positioned(
                    right: 20,
                    child: Icon(
                      Icons.wifi,
                      color: color.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
                ],
              )
            : Icon(icon, color: color, size: 56),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connections list (shown when connections exist)
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyConnectionsList extends StatelessWidget {
  const _FamilyConnectionsList({
    required this.connectionProvider,
    required this.l10n,
  });
  final ConnectionProvider connectionProvider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Caregivers section
          Text(
            l10n.myCaregivers,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (connectionProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Caregivers
            if (connectionProvider.caregivers.isNotEmpty)
              ...connectionProvider.caregivers.map<Widget>(
                (conn) => _buildFamilyMemberCard(context, conn),
              ),

            if (connectionProvider.caregivers.isEmpty) _buildEmptyHint(context),

            // Patients I'm monitoring
            if (connectionProvider.connectedPatients.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.patientsIMonitor,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildEmptyHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Text(
          l10n.noConnections,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
              child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.unknown : name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                connection.status.name == 'accepted'
                    ? l10n.activeStatus
                    : l10n.waitingStatus,
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
              backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
              child: Icon(
                Icons.favorite,
                color: AppColors.successGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.unknown : name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            if (connection.status.name == 'accepted')
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
