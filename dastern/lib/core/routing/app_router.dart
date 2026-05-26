import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/settings/presentation/appearance_settings_page.dart';
import '../../features/settings/presentation/diagnostics_page.dart';
import '../../features/settings/presentation/settings_page.dart';

/// Named routes — keep them as `static const` paths so call-sites use the
/// constant instead of a stringly-typed literal.
class AppRoute {
  const AppRoute._();

  static const String home = '/';
  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsDiagnostics = '/settings/diagnostics';
}

/// Top-level [GoRouter] configuration.
///
/// New feature routes plug in here. The structure intentionally avoids
/// nested ShellRoutes for the initial scaffold; an `AdaptiveScaffold`-based
/// shell will be introduced once at least two top-level destinations exist.
///
/// Spec ref: 00-overview §"Routing", 09-design-system-localization §
/// "AdaptiveScaffold".
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoute.home,
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomePage(),
      ),
      GoRoute(
        path: AppRoute.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'appearance',
            name: 'settings.appearance',
            builder: (BuildContext context, GoRouterState state) =>
                const AppearanceSettingsPage(),
          ),
          GoRoute(
            path: 'diagnostics',
            name: 'settings.diagnostics',
            builder: (BuildContext context, GoRouterState state) =>
                const DiagnosticsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
    ),
  );
});
