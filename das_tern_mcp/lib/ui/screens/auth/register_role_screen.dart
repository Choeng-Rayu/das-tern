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
    final hPad = (size.width * 0.06).clamp(20.0, 40.0);
    final isSmallScreen = size.height < 700;

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
            SizedBox(height: isSmallScreen ? 24.0 : 40.0),

            // ── Header section ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFF1976D2),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    l10n.selectRoleTitle,
                    style: const TextStyle(
                      color: Color(0xFF0D1B2A),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    l10n.selectRoleSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 28.0 : 44.0),

            // ── Patient card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _RoleCard(
                icon: Icons.person_outline,
                title: l10n.patientRole,
                description: l10n.patientRoleDescription,
                onTap: () => Navigator.of(context).pushNamed('/register/patient'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Doctor card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _RoleCard(
                icon: Icons.medical_services_outlined,
                title: l10n.doctorRole,
                description: l10n.doctorRoleDescription,
                onTap: () => Navigator.of(context).pushNamed('/register/doctor'),
              ),
            ),
            SizedBox(height: isSmallScreen ? 28.0 : 44.0),

            // ── Back to login link ──
            AuthLinkRow(
              message: l10n.alreadyHaveAccount,
              actionText: l10n.signIn,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 32),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1B7EDB)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B7EDB).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
