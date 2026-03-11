import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';

/// Data class describing a single tab item for [AppBottomNav].
class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Design-system bottom navigation bar with the five fixed patient tabs:
///
/// | Index | Label       | Icon                      |
/// |-------|-------------|---------------------------|
/// | 0     | Home        | home_outlined / home      |
/// | 1     | Medications | medication_outlined / medication |
/// | 2     | Scan        | qr_code_scanner           |
/// | 3     | Family      | people_outlined / people  |
/// | 4     | Settings    | settings_outlined / settings |
///
/// Usage:
/// ```dart
/// AppBottomNav(
///   currentIndex: _currentIndex,
///   onTap: (i) => setState(() => _currentIndex = i),
/// )
/// ```
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.homeLabel = 'Home',
    this.medicationsLabel = 'Medications',
    this.scanLabel = 'Scan',
    this.familyLabel = 'Family',
    this.settingsLabel = 'Settings',
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // Labels are injected so callers can pass localized strings without
  // requiring BuildContext inside the constructor.
  final String homeLabel;
  final String medicationsLabel;
  final String scanLabel;
  final String familyLabel;
  final String settingsLabel;

  List<_TabItem> _items() => [
        _TabItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: homeLabel,
        ),
        _TabItem(
          icon: Icons.medication_outlined,
          activeIcon: Icons.medication,
          label: medicationsLabel,
        ),
        _TabItem(
          icon: Icons.qr_code_scanner,
          activeIcon: Icons.qr_code_scanner,
          label: scanLabel,
        ),
        _TabItem(
          icon: Icons.people_outlined,
          activeIcon: Icons.people,
          label: familyLabel,
        ),
        _TabItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: settingsLabel,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items();
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.neutral400,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
