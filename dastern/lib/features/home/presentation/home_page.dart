import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass/app_glass_card.dart';
import '../../../shared/widgets/glass/app_glass_nav_bar.dart';
import '../../../shared/widgets/glass/app_scaffold.dart';
import '../../../shared/widgets/states/empty_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.homeTab,
      largeTitle: true,
      actions: <Widget>[
        IconButton(
          tooltip: l.settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go(AppRoute.settings),
        ),
      ],
      destinations: <GlassNavDestination>[
        GlassNavDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l.homeTab,
        ),
        GlassNavDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l.settings,
        ),
      ],
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 1) context.go(AppRoute.settings);
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          kToolbarHeight + AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xxl + AppSpacing.lg, // clear glass nav bar
        ),
        children: <Widget>[
          AppGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.welcomeMessage,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EmptyState(
            icon: Icons.medication_outlined,
            title: l.doseHistoryAppearHere,
          ),
        ],
      ),
    );
  }
}
