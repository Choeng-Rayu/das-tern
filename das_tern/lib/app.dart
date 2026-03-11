import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_theme.dart';
import 'package:das_tern/data/repositories/auth_repository.dart';
import 'package:das_tern/data/repositories/medication_repository.dart';
import 'package:das_tern/data/repositories/notification_repository.dart';
import 'package:das_tern/data/repositories/prescription_repository.dart';
import 'package:das_tern/data/repositories/reminder_repository.dart';
import 'package:das_tern/data/services/auth_service.dart';
import 'package:das_tern/data/services/medication_service.dart';
import 'package:das_tern/data/services/notification_service.dart';
import 'package:das_tern/data/services/prescription_service.dart';
import 'package:das_tern/data/services/reminder_service.dart';
import 'package:das_tern/domain/use_cases/generate_schedule_use_case.dart';
import 'package:das_tern/domain/use_cases/process_ocr_result_use_case.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/family/family_viewmodel.dart';
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
        Provider<MedicationService>(
          create: (_) => MockMedicationService(),
        ),
        Provider<AuthService>(
          create: (_) => MockAuthService(),
        ),
        Provider<PrescriptionService>(
          create: (_) => MockPrescriptionService(),
        ),
        Provider<ReminderService>(
          create: (_) => MockReminderService(),
        ),
        Provider<NotificationService>(
          create: (_) => MockNotificationService(),
        ),
        Provider<MedicationRepository>(
          create: (context) => MedicationRepositoryImpl(
            service: context.read<MedicationService>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            service: context.read<AuthService>(),
          ),
        ),
        Provider<PrescriptionRepository>(
          create: (context) => PrescriptionRepositoryImpl(
            service: context.read<PrescriptionService>(),
          ),
        ),
        Provider<ReminderRepository>(
          create: (context) => ReminderRepositoryImpl(
            service: context.read<ReminderService>(),
          ),
        ),
        Provider<NotificationRepository>(
          create: (context) => NotificationRepositoryImpl(
            service: context.read<NotificationService>(),
          ),
        ),
        Provider<GenerateScheduleUseCase>(
          create: (_) => GenerateScheduleUseCase(),
        ),
        Provider<ProcessOcrResultUseCase>(
          create: (_) => ProcessOcrResultUseCase(),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            medicationRepository: context.read<MedicationRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<MedicationListViewModel>(
          create: (context) => MedicationListViewModel(
            medicationRepository: context.read<MedicationRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<PrescriptionListViewModel>(
          create: (context) => PrescriptionListViewModel(
            repository: context.read<PrescriptionRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<PrescriptionDetailViewModel>(
          create: (context) => PrescriptionDetailViewModel(
            repository: context.read<PrescriptionRepository>(),
          ),
        ),
        ChangeNotifierProvider<CreatePrescriptionViewModel>(
          create: (context) => CreatePrescriptionViewModel(
            repository: context.read<PrescriptionRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<ScanViewModel>(
          create: (_) => ScanViewModel()..load.execute(),
        ),
        ChangeNotifierProvider<OcrReviewViewModel>(
          create: (context) => OcrReviewViewModel(
            processOcrResultUseCase: context.read<ProcessOcrResultUseCase>(),
          ),
        ),
        ChangeNotifierProvider<ReminderScheduleViewModel>(
          create: (context) => ReminderScheduleViewModel(
            reminderRepository: context.read<ReminderRepository>(),
            generateScheduleUseCase: context.read<GenerateScheduleUseCase>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<FamilyViewModel>(
          create: (context) => FamilyViewModel(
            authRepository: context.read<AuthRepository>(),
          )..load.execute(),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            notificationRepository: context.read<NotificationRepository>(),
            authRepository: context.read<AuthRepository>(),
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