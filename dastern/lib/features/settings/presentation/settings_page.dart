import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass/app_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.settings,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoute.home),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + 8),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.appearance),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.settingsAppearance),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.settingsDiagnostics),
          ),
        ],
      ),
    );
  }
}
