import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';

/// Settings landing page. Currently routes only to Appearance; additional
/// sections (Account, Connections, Subscription) plug in here as they
/// land in future feature specs.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.settingsAppearance),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.settingsAppearance),
          ),
        ],
      ),
    );
  }
}
