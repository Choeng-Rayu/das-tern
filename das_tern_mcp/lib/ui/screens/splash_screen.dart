import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../widgets/splash/cinematic_splash_animation.dart';

/// Splash screen shown on app launch.
/// Plays a cinematic DasTern logo reveal animation, then
/// checks auth state and routes to login or dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CinematicSplashAnimation(onAnimationComplete: _navigateAfterSplash),
    );
  }

  Future<void> _navigateAfterSplash() async {
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
      Navigator.of(context).pushReplacementNamed(AppRouter.welcome);
    }
  }
}
