import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_header.dart';
import 'package:das_tern_mcp/core/widgets/app_bottom_nav.dart';
import 'package:das_tern_mcp/l10n/app_localizations.dart';

/// Design-system scaffold that composes [AppHeader] and [AppBottomNav] with a
/// plain [Scaffold].
///
/// All constructor parameters are optional — omit [title] for screens that
/// manage their own app-bar, or set [showBottomNav] to `false` for full-screen
/// flows.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   title: 'Home',
///   currentIndex: 0,
///   showBackButton: false,
///   showBottomNav: true,
///   onBottomNavTap: (i) => _navigate(i),
///   body: const HomeContent(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.currentIndex = 0,
    this.showBackButton = false,
    this.showBottomNav = true,
    this.actions,
    this.floatingActionButton,
    this.onBottomNavTap,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  /// Main body content.
  final Widget body;

  /// App-bar title text. Pass `null` to hide the app-bar.
  final String? title;

  /// Currently selected tab index (0–4). Used by [AppBottomNav].
  final int currentIndex;

  /// Whether to render a back-arrow in the app-bar.
  final bool showBackButton;

  /// Whether to render the bottom navigation bar.
  final bool showBottomNav;

  /// Trailing app-bar action buttons.
  final List<Widget>? actions;

  /// Optional FAB forwarded to [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// Overrides the default bottom-nav tap handler.
  ///
  /// When `null`, taps do nothing — the parent widget should provide a
  /// callback when using [AppScaffold] inside a shell that manages its own
  /// [IndexedStack].
  final ValueChanged<int>? onBottomNavTap;

  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title != null
          ? AppHeader(
              title: title,
              showBackButton: showBackButton,
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(
              currentIndex: currentIndex,
              onTap: onBottomNavTap ?? (_) {},
              homeLabel: l10n?.homeTab ?? 'Home',
              medicationsLabel: l10n?.medicationsAnalysis ?? 'Medications',
              scanLabel: l10n?.scanPrescriptionTab ?? 'Scan',
              familyLabel: l10n?.familyFeatures ?? 'Family',
              settingsLabel: l10n?.settings ?? 'Settings',
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
