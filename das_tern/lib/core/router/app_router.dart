import 'package:das_tern/ui/family/family_view.dart';
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

  static const Map<int, String> tabRoutes = <int, String>{
    0: home,
    1: medications,
    2: scan,
    3: family,
    4: settings,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.home:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
      case AppRouter.medications:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationListView(),
        );
<<<<<<< HEAD
      case AppRouter.scan:
        return MaterialPageRoute<void>(
          builder: (_) => const _PlaceholderView(title: 'Scan'),
        );
      case AppRouter.family:
        return MaterialPageRoute<void>(
          builder: (_) => const _PlaceholderView(title: 'Family'),
        );
      case AppRouter.settings:
=======
      case scan:
        return MaterialPageRoute<void>(builder: (_) => const ScanView());
      case family:
        return MaterialPageRoute<void>(builder: (_) => const FamilyView());
      case settings:
        return MaterialPageRoute<void>(builder: (_) => const SettingsView());
      case prescriptions:
>>>>>>> 75e1b1e0b17b99830ebed2d7050ad626a50b04bf
        return MaterialPageRoute<void>(
          builder: (_) => const PrescriptionListView(),
        );
      case prescriptionDetail:
        return MaterialPageRoute<void>(
          builder: (_) => const PrescriptionDetailView(),
          settings: settings,
        );
      case createPrescription:
        return MaterialPageRoute<void>(
          builder: (_) => const CreatePrescriptionView(),
        );
      case ocrReview:
        return MaterialPageRoute<void>(
          builder: (_) => const OcrReviewView(),
          settings: settings,
        );
      case reminderSchedule:
        return MaterialPageRoute<void>(
          builder: (_) => const ReminderScheduleView(),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
    }
  }
}
<<<<<<< HEAD

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      currentIndex: AppRouter.tabRoutes.entries
          .firstWhere(
            (entry) => entry.value == ModalRoute.of(context)?.settings.name,
            orElse: () => const MapEntry<int, String>(0, AppRouter.home),
          )
          .key,
      body: Center(child: Text('$title screen is not migrated yet')),
    );
  }
}
=======
>>>>>>> 75e1b1e0b17b99830ebed2d7050ad626a50b04bf
