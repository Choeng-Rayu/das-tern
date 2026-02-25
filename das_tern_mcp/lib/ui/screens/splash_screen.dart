import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_switcher.dart';

/// Splash screen shown on app launch.
/// Checks auth state and routes to login or dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Short delay for branding display
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Load auth state (applies dev bypass if DevConfig.skipAuth == true)
    final auth = context.read<AuthProvider>();
    await auth.loadAuthState();
    if (!mounted) return;

    if (auth.isAuthenticated) {
      final role = auth.user?['role'] as String? ?? '';
      if (role == 'DOCTOR') {
        Navigator.of(context).pushReplacementNamed(AppRouter.doctorHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.patientHome);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B7A9E), Color(0xFF1A5276), Color(0xFF154360)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language switcher in top-right
              const Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.lg,
                child: LanguageSwitcherButton(),
              ),

              // Centered content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appTagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
