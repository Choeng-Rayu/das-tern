import 'package:das_tern/ui/auth/forgot_password_view.dart';
import 'package:das_tern/ui/auth/login_view.dart';
import 'package:das_tern/ui/auth/otp_verification_view.dart';
import 'package:das_tern/ui/auth/register_view.dart';
import 'package:das_tern/ui/auth/welcome_view.dart';
import 'package:das_tern/ui/dose/dose_schedule_view.dart';
import 'package:das_tern/ui/family/family_view.dart';
import 'package:das_tern/ui/health/health_dashboard_view.dart';
import 'package:das_tern/ui/home/home_view.dart';
import 'package:das_tern/ui/medication/medication_list_view.dart';
import 'package:das_tern/ui/prescription/create_prescription_view.dart';
import 'package:das_tern/ui/prescription/prescription_detail_view.dart';
import 'package:das_tern/ui/prescription/prescription_list_view.dart';
import 'package:das_tern/ui/reminder/reminder_schedule_view.dart';
import 'package:das_tern/ui/scan/ocr_review_view.dart';
import 'package:das_tern/ui/scan/scan_view.dart';
import 'package:das_tern/ui/settings/settings_view.dart';
import 'package:flutter/material.dart';

class AppRouter {
  // Auth routes
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String home = '/';
  static const String medications = '/medications';
  static const String scan = '/scan';
  static const String family = '/family';
  static const String settings = '/settings';
  static const String prescriptions = '/prescriptions';
  static const String prescriptionDetail = '/prescriptions/detail';
  static const String createPrescription = '/prescriptions/create';
  static const String ocrReview = '/scan/ocr-review';
  static const String reminderSchedule = '/reminder/schedule';
  static const String doseSchedule = '/dose/schedule';
  static const String healthDashboard = '/health';

  static const Map<int, String> tabRoutes = <int, String>{
    0: home,
    1: medications,
    2: scan,
    3: family,
    4: settings,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case AppRouter.welcome:
        return MaterialPageRoute<void>(builder: (_) => const WelcomeView());
      case AppRouter.login:
        return MaterialPageRoute<void>(builder: (_) => const LoginView());
      case AppRouter.register:
        return MaterialPageRoute<void>(builder: (_) => const RegisterView());
      case AppRouter.otpVerification:
        return MaterialPageRoute<void>(
          builder: (_) => const OtpVerificationView(),
        );
      case AppRouter.forgotPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordView(),
        );

      // Main app
      case AppRouter.home:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
      case AppRouter.medications:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationListView(),
        );
      case AppRouter.scan:
        return MaterialPageRoute<void>(builder: (_) => const ScanView());
      case AppRouter.family:
        return MaterialPageRoute<void>(builder: (_) => const FamilyView());
      case AppRouter.settings:
        return MaterialPageRoute<void>(builder: (_) => const SettingsView());
      case AppRouter.prescriptions:
        return MaterialPageRoute<void>(
          builder: (_) => const PrescriptionListView(),
        );
      case AppRouter.prescriptionDetail:
        return MaterialPageRoute<void>(
          builder: (_) => const PrescriptionDetailView(),
          settings: settings,
        );
      case AppRouter.createPrescription:
        return MaterialPageRoute<void>(
          builder: (_) => const CreatePrescriptionView(),
        );
      case AppRouter.ocrReview:
        return MaterialPageRoute<void>(
          builder: (_) => const OcrReviewView(),
          settings: settings,
        );
      case AppRouter.reminderSchedule:
        return MaterialPageRoute<void>(
          builder: (_) => const ReminderScheduleView(),
        );
      case AppRouter.doseSchedule:
        return MaterialPageRoute<void>(
          builder: (_) => const DoseScheduleView(),
        );
      case AppRouter.healthDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const HealthDashboardView(),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
    }
  }
}
