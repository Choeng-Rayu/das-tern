import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Screen for choosing registration role: Patient or Doctor.
class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthGradientScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              showBackButton: true,
              onBack: () => Navigator.of(context).pop(),
              trailing: const LanguageSwitcherButton(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFF1976D2),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.selectRoleTitle,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.selectRoleSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Patient card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _RoleCard(
                icon: Icons.person_outline,
                title: l10n.patientRole,
                description: l10n.patientRoleDescription,
                onTap: () =>
                    Navigator.of(context).pushNamed('/register/patient'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Doctor card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _RoleCard(
                icon: Icons.medical_services_outlined,
                title: l10n.doctorRole,
                description: l10n.doctorRoleDescription,
                onTap: () =>
                    Navigator.of(context).pushNamed('/register/doctor'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl * 2),

            // ── Back to login link ──
            AuthLinkRow(
              message: l10n.alreadyHaveAccount,
              actionText: l10n.signIn,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1B7EDB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1565C0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFBDD8F5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBDD8F5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
