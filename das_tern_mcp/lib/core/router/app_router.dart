import 'package:flutter/material.dart';

import '../../utils/app_router.dart' as legacy;

/// Non-breaking wrapper around legacy router during migration.
class AppRouter {
  static const String splash = legacy.AppRouter.splash;
  static const String welcome = legacy.AppRouter.welcome;
  static const String login = legacy.AppRouter.login;
  static const String registerRole = legacy.AppRouter.registerRole;
  static const String registerPatient = legacy.AppRouter.registerPatient;
  static const String registerDoctor = legacy.AppRouter.registerDoctor;
  static const String otpVerification = legacy.AppRouter.otpVerification;
  static const String forgotPassword = legacy.AppRouter.forgotPassword;
  static const String resetPassword = legacy.AppRouter.resetPassword;
  static const String patientHome = legacy.AppRouter.patientHome;
  static const String doctorHome = legacy.AppRouter.doctorHome;
  static const String doctorPatientDetail = legacy.AppRouter.doctorPatientDetail;
  static const String doctorMedPatients = legacy.AppRouter.doctorMedPatients;
  static const String doctorPendingPatients =
      legacy.AppRouter.doctorPendingPatients;

  static const String familyConnect = legacy.AppRouter.familyConnect;
  static const String familyAccessLevel = legacy.AppRouter.familyAccessLevel;
  static const String familyTokenDisplay = legacy.AppRouter.familyTokenDisplay;
  static const String familyScan = legacy.AppRouter.familyScan;
  static const String familyEnterCode = legacy.AppRouter.familyEnterCode;
  static const String familyPreview = legacy.AppRouter.familyPreview;
  static const String familyAccessList = legacy.AppRouter.familyAccessList;
  static const String familyCaregiverDashboard =
      legacy.AppRouter.familyCaregiverDashboard;
  static const String familyGracePeriod = legacy.AppRouter.familyGracePeriod;
  static const String familyHistory = legacy.AppRouter.familyHistory;
  static const String familyPatientDetail = legacy.AppRouter.familyPatientDetail;

  static const String subscriptionManage = legacy.AppRouter.subscriptionManage;
  static const String subscriptionUpgrade =
      legacy.AppRouter.subscriptionUpgrade;
  static const String subscriptionPaymentMethod =
      legacy.AppRouter.subscriptionPaymentMethod;
  static const String subscriptionBakongPayment =
      legacy.AppRouter.subscriptionBakongPayment;
  static const String subscriptionQrCode = legacy.AppRouter.subscriptionQrCode;
  static const String subscriptionSuccess = legacy.AppRouter.subscriptionSuccess;

  static const String doctorCreatePrescription =
      legacy.AppRouter.doctorCreatePrescription;
  static const String patientCreateMedicine =
      legacy.AppRouter.patientCreateMedicine;
  static const String patientScanPrescription =
      legacy.AppRouter.patientScanPrescription;
  static const String prescriptionDetail = legacy.AppRouter.prescriptionDetail;
  static const String medicationChoice = legacy.AppRouter.medicationChoice;
  static const String patientCreateBatch = legacy.AppRouter.patientCreateBatch;
  static const String batchDetail = legacy.AppRouter.batchDetail;
  static const String ocrPreview = legacy.AppRouter.ocrPreview;
  static const String patientPrescriptionWizard =
      legacy.AppRouter.patientPrescriptionWizard;
  static const String prescriptionSuccess = legacy.AppRouter.prescriptionSuccess;

  static const String patientRecordVital = legacy.AppRouter.patientRecordVital;
  static const String patientVitalTrend = legacy.AppRouter.patientVitalTrend;
  static const String patientVitalThresholds =
      legacy.AppRouter.patientVitalThresholds;
  static const String patientEmergency = legacy.AppRouter.patientEmergency;
  static const String patientNotifications =
      legacy.AppRouter.patientNotifications;
  static const String doctorNotifications =
      legacy.AppRouter.doctorNotifications;
  static const String patientEditProfile = legacy.AppRouter.patientEditProfile;
  static const String patientChangePassword =
      legacy.AppRouter.patientChangePassword;
  static const String patientHealthReport = legacy.AppRouter.patientHealthReport;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return legacy.AppRouter.generateRoute(settings);
  }
}
