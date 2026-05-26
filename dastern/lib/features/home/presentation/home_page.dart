import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/states/empty_state.dart';

/// Home / dashboard placeholder.
///
/// Replaced piece-by-piece as feature specs land:
/// - Today's doses ← `04-reminder-adherence`
/// - Active prescriptions ← `03-prescription-medication`
/// - Connections quick-look ← `05-family-doctor-connections`
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.homeTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRoute.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.homeWelcome,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.homeWelcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EmptyState(icon: Icons.medication_outlined, title: l.homePlaceholder),
        ],
      ),
    );
  }
}
