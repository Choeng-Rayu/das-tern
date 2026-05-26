import 'package:flutter/material.dart';

import '../../../core/theme/tokens/breakpoints.dart';
import 'app_glass_header.dart';
import 'app_glass_nav_bar.dart';
import 'app_mesh_background.dart';

/// Role-aware glass shell that wraps every page.
///
/// **Never** use [Scaffold] directly inside a feature page — always use
/// [AppScaffold]. It composes:
/// - [AppMeshBackground] — persistent animated orb background.
/// - [AppGlassHeader] — blurring large-title app bar.
/// - [AppGlassNavBar] — floating glass pill nav (compact) or rail (wider).
/// - [body] — the page content.
///
/// The [destinations] and [selectedIndex] / [onDestinationSelected] are
/// optional. When omitted the shell renders without a nav bar (e.g. auth
/// screens, detail pages).
///
/// Spec ref: liquid-glass-flutter SKILL.md §"Role-aware navigation shell".
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.largeTitle = false,
    this.destinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool largeTitle;

  /// Navigation destinations. Pass `null` for screens without a nav bar.
  final List<GlassNavDestination>? destinations;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final bp = Breakpoint.of(context);
    final hasNav = destinations != null &&
        selectedIndex != null &&
        onDestinationSelected != null;

    final header = title != null
        ? AppGlassHeader(
            title: title!,
            subtitle: subtitle,
            leading: leading,
            actions: actions,
            large: largeTitle,
          )
        : null;

    // Compact — bottom glass nav bar
    if (bp.isCompact) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: header,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: <Widget>[
            const AppMeshBackground(),
            body,
            if (hasNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppGlassNavBar(
                  destinations: destinations!,
                  selectedIndex: selectedIndex!,
                  onDestinationSelected: onDestinationSelected!,
                ),
              ),
          ],
        ),
      );
    }

    // Medium / expanded — navigation rail
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: true,
      appBar: header,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: <Widget>[
          const AppMeshBackground(),
          if (hasNav)
            Row(
              children: <Widget>[
                NavigationRail(
                  backgroundColor: Colors.transparent,
                  destinations: destinations!
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon ?? d.icon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(growable: false),
                  selectedIndex: selectedIndex!,
                  onDestinationSelected: onDestinationSelected!,
                  extended: bp.isExpanded,
                  labelType: bp.isExpanded
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          else
            body,
        ],
      ),
    );
  }
}
