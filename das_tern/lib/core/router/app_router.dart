import 'package:das_tern/ui/home/home_view.dart';
import 'package:das_tern/ui/medication/medication_list_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String medications = '/medications';
  static const String scan = '/scan';
  static const String family = '/family';
  static const String settings = '/settings';

  static const Map<int, String> tabRoutes = <int, String>{
    0: home,
    1: medications,
    2: scan,
    3: family,
    4: settings,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
      case medications:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationListView(),
        );
      case scan:
        return MaterialPageRoute<void>(
          builder: (_) => const _PlaceholderView(title: 'Scan'),
        );
      case family:
        return MaterialPageRoute<void>(
          builder: (_) => const _PlaceholderView(title: 'Family'),
        );
      case settings:
        return MaterialPageRoute<void>(
          builder: (_) => const _PlaceholderView(title: 'Settings'),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const HomeView());
    }
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      currentIndex: AppRouter.tabRoutes.entries
          .firstWhere((entry) => entry.value == ModalRoute.of(context)?.settings.name,
              orElse: () => const MapEntry<int, String>(0, AppRouter.home))
          .key,
      body: Center(
        child: Text('$title screen is not migrated yet'),
      ),
    );
  }
}
