import 'package:flutter/material.dart';

import '../../core/theme/tokens/breakpoints.dart';

/// Adaptive shell that picks the right navigation surface for the current
/// screen width:
/// - **Compact** (<600dp): bottom navigation bar.
/// - **Medium** (600–839dp): navigation rail.
/// - **Expanded** (≥840dp): permanent navigation drawer-style rail.
///
/// Each destination is a [NavigationDestination] (Material 3). The widget
/// translates them automatically into rail destinations on wider screens.
///
/// Spec ref: 09-design-system-localization §Requirement 9 (`AdaptiveScaffold`).
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
  });

  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final Breakpoint bp = Breakpoint.of(context);
    if (bp.isCompact) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: <Widget>[
          NavigationRail(
            destinations: destinations
                .map(
                  (NavigationDestination d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
                )
                .toList(growable: false),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            extended: bp.isExpanded,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
