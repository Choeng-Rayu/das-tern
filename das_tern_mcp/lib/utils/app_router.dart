import 'package:flutter/material.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_role_screen.dart';
import '../ui/screens/auth/register_patient_screen.dart';
import '../ui/screens/auth/register_doctor_screen.dart';
import '../ui/screens/auth/otp_verification_screen.dart';
import '../ui/screens/patient/patient_shell.dart';
import '../ui/screens/doctor/doctor_shell.dart';
import '../ui/screens/splash_screen.dart';

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
      default:
        return _buildRoute(const Scaffold(
          body: Center(child: Text('Page not found')),
        ));
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
