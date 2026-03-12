import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_theme.dart';
import 'package:das_tern/data/repositories/auth_repository.dart';
import 'package:das_tern/data/repositories/connection_repository.dart';
import 'package:das_tern/data/repositories/dose_repository.dart';
import 'package:das_tern/data/repositories/health_repository.dart';
import 'package:das_tern/data/repositories/medication_repository.dart';
import 'package:das_tern/data/repositories/notification_repository.dart';
import 'package:das_tern/data/repositories/prescription_repository.dart';
import 'package:das_tern/data/repositories/reminder_repository.dart';
import 'package:das_tern/data/services/auth_service.dart';
import 'package:das_tern/data/services/connection_service.dart';
import 'package:das_tern/data/services/dose_service.dart';
import 'package:das_tern/data/services/health_service.dart';
import 'package:das_tern/data/services/medication_service.dart';
import 'package:das_tern/data/services/notification_service.dart';
import 'package:das_tern/data/services/prescription_service.dart';
import 'package:das_tern/data/services/reminder_service.dart';
import 'package:das_tern/domain/use_cases/generate_schedule_use_case.dart';
import 'package:das_tern/domain/use_cases/process_ocr_result_use_case.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/auth/auth_viewmodel.dart';
import 'package:das_tern/ui/dose/dose_schedule_viewmodel.dart';
import 'package:das_tern/ui/family/family_viewmodel.dart';
import 'package:das_tern/ui/health/health_viewmodel.dart';
import 'package:das_tern/ui/home/home_viewmodel.dart';
import 'package:das_tern/ui/medication/medication_list_viewmodel.dart';
import 'package:das_tern/ui/prescription/create_prescription_viewmodel.dart';
import 'package:das_tern/ui/prescription/prescription_detail_viewmodel.dart';
import 'package:das_tern/ui/prescription/prescription_list_viewmodel.dart';
import 'package:das_tern/ui/reminder/reminder_schedule_viewmodel.dart';
import 'package:das_tern/ui/scan/ocr_review_viewmodel.dart';
import 'package:das_tern/ui/scan/scan_viewmodel.dart';
import 'package:das_tern/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Services ──
        Provider<AuthService>(create: (_) => MockAuthService()),
        Provider<MedicationService>(create: (_) => MockMedicationService()),
        Provider<PrescriptionService>(create: (_) => MockPrescriptionService()),
        Provider<ReminderService>(create: (_) => MockReminderService()),
        Provider<NotificationService>(create: (_) => MockNotificationService()),
        Provider<DoseService>(create: (_) => MockDoseService()),
        Provider<HealthService>(create: (_) => MockHealthService()),
        Provider<ConnectionService>(create: (_) => MockConnectionService()),

        // ── Repositories ──
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(service: ctx.read<AuthService>()),
        ),
        Provider<MedicationRepository>(
          create: (ctx) =>
              MedicationRepositoryImpl(service: ctx.read<MedicationService>()),
        ),
        Provider<PrescriptionRepository>(
          create: (ctx) => PrescriptionRepositoryImpl(
            service: ctx.read<PrescriptionService>(),
          ),
        ),
        Provider<ReminderRepository>(
          create: (ctx) =>
              ReminderRepositoryImpl(service: ctx.read<ReminderService>()),
        ),
        Provider<NotificationRepository>(
          create: (ctx) => NotificationRepositoryImpl(
            service: ctx.read<NotificationService>(),
          ),
        ),
        Provider<DoseRepository>(
          create: (ctx) => DoseRepositoryImpl(service: ctx.read<DoseService>()),
        ),
        Provider<HealthRepository>(
          create: (ctx) =>
              HealthRepositoryImpl(service: ctx.read<HealthService>()),
        ),
        Provider<ConnectionRepository>(
          create: (ctx) =>
              ConnectionRepositoryImpl(service: ctx.read<ConnectionService>()),
        ),

        // ── Use Cases ──
        Provider<GenerateScheduleUseCase>(
          create: (_) => GenerateScheduleUseCase(),
        ),
        Provider<ProcessOcrResultUseCase>(
          create: (_) => ProcessOcrResultUseCase(),
        ),

        // ── ViewModels ──
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) =>
              AuthViewModel(authRepository: ctx.read<AuthRepository>())
                ..loadCurrentUser.execute(),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            medicationRepository: ctx.read<MedicationRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<MedicationListViewModel>(
          create: (ctx) => MedicationListViewModel(
            medicationRepository: ctx.read<MedicationRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<PrescriptionListViewModel>(
          create: (ctx) => PrescriptionListViewModel(
            repository: ctx.read<PrescriptionRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<PrescriptionDetailViewModel>(
          create: (ctx) => PrescriptionDetailViewModel(
            repository: ctx.read<PrescriptionRepository>(),
          ),
        ),
        ChangeNotifierProvider<CreatePrescriptionViewModel>(
          create: (ctx) => CreatePrescriptionViewModel(
            repository: ctx.read<PrescriptionRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<ScanViewModel>(
          create: (_) => ScanViewModel()..load.execute(),
        ),
        ChangeNotifierProvider<OcrReviewViewModel>(
          create: (ctx) => OcrReviewViewModel(
            processOcrResultUseCase: ctx.read<ProcessOcrResultUseCase>(),
          ),
        ),
        ChangeNotifierProvider<ReminderScheduleViewModel>(
          create: (ctx) => ReminderScheduleViewModel(
            reminderRepository: ctx.read<ReminderRepository>(),
            generateScheduleUseCase: ctx.read<GenerateScheduleUseCase>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<DoseScheduleViewModel>(
          create: (ctx) =>
              DoseScheduleViewModel(doseRepository: ctx.read<DoseRepository>())
                ..load.execute(),
        ),
        ChangeNotifierProvider<HealthViewModel>(
          create: (ctx) =>
              HealthViewModel(healthRepository: ctx.read<HealthRepository>())
                ..load.execute(),
        ),
        ChangeNotifierProvider<FamilyViewModel>(
          create: (ctx) =>
              FamilyViewModel(authRepository: ctx.read<AuthRepository>())
                ..load.execute(),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (ctx) => SettingsViewModel(
            notificationRepository: ctx.read<NotificationRepository>(),
            authRepository: ctx.read<AuthRepository>(),
          )..load.execute(),
        ),
      ],
      child: MaterialApp(
        title: 'DasTern',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppRouter.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
