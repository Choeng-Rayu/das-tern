import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Screen for choosing registration role: Patient or Doctor.
/// Also offers a direct "Register with Telegram" option that bypasses role
/// selection (user role defaults to PATIENT when using Telegram).
class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key});

  @override
  State<RegisterRoleScreen> createState() => _RegisterRoleScreenState();
}

class _RegisterRoleScreenState extends State<RegisterRoleScreen> {
  Future<void> _handleTelegramRegister() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithTelegram();

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(
        context,
      ).pushReplacementNamed(role == 'DOCTOR' ? '/doctor' : '/patient');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final hPad = (size.width * 0.06).clamp(16.0, 40.0);
    final isSmallScreen = size.height < 700;
    final topGap = isSmallScreen ? AppSpacing.lg : AppSpacing.xxl;
    final iconSize = isSmallScreen ? 56.0 : 72.0;
    final iconInnerSize = isSmallScreen ? 28.0 : 36.0;
    final titleFontSize = size.width < 360 ? 18.0 : 22.0;

    return AuthGradientScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              showBackButton: true,
              onBack: () => Navigator.of(context).pop(),
              trailing: const LanguageSwitcherButton(lightBackground: true),
            ),
            SizedBox(height: topGap),

            // ── Title ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: const Color(0xFF1976D2),
                      size: iconInnerSize,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.selectRoleTitle,
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: titleFontSize,
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
            SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.xl),

            // ── Patient card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
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
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _RoleCard(
                icon: Icons.medical_services_outlined,
                title: l10n.doctorRole,
                description: l10n.doctorRoleDescription,
                onTap: () =>
                    Navigator.of(context).pushNamed('/register/doctor'),
              ),
            ),
            SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.xl),

            // ── OR section ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.orRegisterWith,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Telegram quick-register button ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _handleTelegramRegister,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF229ED9),
                    size: 20,
                  ),
                  label: Text(
                    l10n.registerWithTelegram,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF229ED9),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: topGap),

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

// ── Role selection card ──────────────────────────────────────────────────────

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
          border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
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
            const Icon(Icons.chevron_right, color: Color(0xFFBDD8F5), size: 22),
          ],
        ),
      ),
    );
  }
}
