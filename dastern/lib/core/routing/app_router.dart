import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/method_chooser_page.dart';
import '../../features/auth/presentation/pages/profile_bootstrap_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_credentials_page.dart';
import '../../features/auth/presentation/pages/verify_practice_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/settings/presentation/appearance_settings_page.dart';
import '../../features/settings/presentation/diagnostics_page.dart';
import '../../features/settings/presentation/settings_page.dart';

class AppRoute {
  const AppRoute._();

  static const String welcome = '/welcome';
  static const String methodChooser = '/method-chooser';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyPractice = '/verify-practice';
  static const String profileBootstrap = '/profile-bootstrap';
  static const String home = '/';
  static const String patientHome = '/patient/home';
  static const String doctorHome = '/doctor/home';
  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsDiagnostics = '/settings/diagnostics';
}

/// Redirect guard: unauthenticated users → /welcome; bootstrapped users
/// skip /profile-bootstrap.
String? _redirect(BuildContext context, GoRouterState state) {
  // Guard against Supabase not yet initialized (e.g. in widget tests).
  bool isAuth = false;
  try {
    isAuth = Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    isAuth = false;
  }
  final loc = state.matchedLocation;

  final authRoutes = <String>{
    AppRoute.welcome,
    AppRoute.methodChooser,
    AppRoute.signIn,
    AppRoute.signUp,
  };

  if (!isAuth && !authRoutes.contains(loc)) return AppRoute.welcome;
  if (isAuth && authRoutes.contains(loc)) return AppRoute.home;
  return null;
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoute.home,
    redirect: _redirect,
    routes: <RouteBase>[
      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.welcome,
        builder: (_, _) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoute.methodChooser,
        builder: (_, _) => const MethodChooserPage(),
      ),
      GoRoute(
        path: AppRoute.signIn,
        builder: (_, _) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoute.signUp,
        builder: (_, _) => const SignUpCredentialsPage(),
      ),
      GoRoute(
        path: AppRoute.profileBootstrap,
        builder: (_, _) => const ProfileBootstrapPage(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoute.resetPassword,
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoute.verifyPractice,
        builder: (_, _) => const VerifyPracticePage(),
      ),
      // ── App shell ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.home,
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: AppRoute.patientHome,
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: AppRoute.doctorHome,
        builder: (_, _) => const HomePage(), // replaced by DoctorHomePage in spec 06
      ),
      GoRoute(
        path: AppRoute.settings,
        builder: (_, _) => const SettingsPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'appearance',
            builder: (_, _) => const AppearanceSettingsPage(),
          ),
          GoRoute(
            path: 'diagnostics',
            builder: (_, _) => const DiagnosticsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Not found')),
    ),
  );
});
