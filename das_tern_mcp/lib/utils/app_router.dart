import 'package:flutter/material.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_role_screen.dart';
import '../ui/screens/auth/register_patient_screen.dart';
import '../ui/screens/auth/register_doctor_screen.dart';
import '../ui/screens/auth/otp_verification_screen.dart';
import '../ui/screens/patient/patient_shell.dart';
import '../ui/screens/doctor/doctor_shell.dart';
import '../ui/screens/doctor/patient_detail_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/family_ui/family_connect_intro_screen.dart';
import '../ui/screens/family_ui/access_level_selection_screen.dart';
import '../ui/screens/family_ui/token_display_screen.dart';
import '../ui/screens/family_ui/qr_scanner_screen.dart';
import '../ui/screens/family_ui/code_entry_screen.dart';
import '../ui/screens/family_ui/connection_preview_screen.dart';
import '../ui/screens/family_ui/family_access_list_screen.dart';
import '../ui/screens/family_ui/caregiver_dashboard_screen.dart';
import '../ui/screens/family_ui/grace_period_settings_screen.dart';
import '../ui/screens/family_ui/connection_history_screen.dart';
import '../ui/screens/patient/upgrade_plan_screen.dart';
import '../ui/screens/patient/payment_method_screen.dart';
import '../ui/screens/patient/bakong_payment_screen.dart';
import '../ui/screens/patient/payment_qr_screen.dart';
import '../ui/screens/patient/payment_success_screen.dart';

/// Centralized route definitions.
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String registerRole = '/register-role';
  static const String registerPatient = '/register/patient';
  static const String registerDoctor = '/register/doctor';
  static const String otpVerification = '/otp-verification';
  static const String patientHome = '/patient';
  static const String doctorHome = '/doctor';
  static const String doctorPatientDetail = '/doctor/patient-detail';

  // Family feature routes
  static const String familyConnect = '/family/connect';
  static const String familyAccessLevel = '/family/access-level';
  static const String familyTokenDisplay = '/family/token-display';
  static const String familyScan = '/family/scan';
  static const String familyEnterCode = '/family/enter-code';
  static const String familyPreview = '/family/preview';
  static const String familyAccessList = '/family/access-list';
  static const String familyCaregiverDashboard = '/family/caregiver-dashboard';
  static const String familyGracePeriod = '/family/grace-period';
  static const String familyHistory = '/family/history';

  // Subscription/payment routes
  static const String subscriptionUpgrade = '/subscription/upgrade';
  static const String subscriptionPaymentMethod = '/subscription/payment-method';
  static const String subscriptionBakongPayment = '/subscription/bakong-payment';
  static const String subscriptionQrCode = '/subscription/qr-code';
  static const String subscriptionSuccess = '/subscription/success';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case login:
        return _buildRoute(const LoginScreen());
      case registerRole:
        return _buildRoute(const RegisterRoleScreen());
      case registerPatient:
        return _buildRoute(const RegisterPatientScreen());
      case registerDoctor:
        return _buildRoute(const RegisterDoctorScreen());
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(OtpVerificationScreen(
          phoneNumber: args?['phoneNumber'] ?? '',
        ));
      case patientHome:
        return _buildRoute(const PatientShell());
      case doctorHome:
        return _buildRoute(const DoctorShell());
      case doctorPatientDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(PatientDetailScreen(
          patientId: args?['patientId'] ?? '',
        ));

      // Family routes
      case familyConnect:
        return _buildRoute(const FamilyConnectIntroScreen());
      case familyAccessLevel:
        return _buildRoute(const AccessLevelSelectionScreen());
      case familyTokenDisplay:
        return _buildRoute(const TokenDisplayScreen(), settings: settings);
      case familyScan:
        return _buildRoute(const QRScannerScreen());
      case familyEnterCode:
        return _buildRoute(const CodeEntryScreen());
      case familyPreview:
        return _buildRoute(const ConnectionPreviewScreen(), settings: settings);
      case familyAccessList:
        return _buildRoute(const FamilyAccessListScreen());
      case familyCaregiverDashboard:
        return _buildRoute(const CaregiverDashboardScreen(),
            settings: settings);
      case familyGracePeriod:
        return _buildRoute(const GracePeriodSettingsScreen());
      case familyHistory:
        return _buildRoute(const ConnectionHistoryScreen());

      // Subscription/payment routes
      case subscriptionUpgrade:
        return _buildRoute(const UpgradePlanScreen());
      case subscriptionPaymentMethod:
        return _buildRoute(const PaymentMethodScreen(), settings: settings);
      case subscriptionBakongPayment:
        return _buildRoute(const BakongPaymentScreen(), settings: settings);
      case subscriptionQrCode:
        return _buildRoute(const PaymentQrScreen(), settings: settings);
      case subscriptionSuccess:
        return _buildRoute(const PaymentSuccessScreen());

      default:
        return _buildRoute(const Scaffold(
          body: Center(child: Text('Page not found')),
        ));
    }
  }

  static MaterialPageRoute _buildRoute(Widget page,
      {RouteSettings? settings}) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
