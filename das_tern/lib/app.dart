import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_theme.dart';
import 'package:das_tern/data/repositories/medication_repository.dart';
import 'package:das_tern/data/services/medication_service.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/home/home_viewmodel.dart';
import 'package:das_tern/ui/medication/medication_list_viewmodel.dart';
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
        Provider<MedicationRepository>(
          create: (context) => MedicationRepositoryImpl(
            service: context.read<MedicationService>(),
          ),
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