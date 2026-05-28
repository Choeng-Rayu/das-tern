import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'tab/doctor_home_tab.dart';
import 'doctor_patients_tab.dart';
import 'tab/doctor_prescriptions_tab.dart';
import 'doctor_prescription_history_tab.dart';
import 'tab/doctor_settings_tab.dart';

/// Doctor dashboard shell with 5-tab bottom navigation.
/// Figma tabs: ទំព័រដើម | តាមដានអ្នកជំងឺ | បង្កើតវេជ្ជបញ្ជា | ប្រវិត្តវេជ្ជបញ្ជារ | ការកំណត់
class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    DoctorHomeTab(onSwitchTab: _switchTab),
    const DoctorPatientsTab(),
    const DoctorPrescriptionsTab(),
    const DoctorPrescriptionHistoryTab(),
    const DoctorSettingsTab(),
  ];

  void _switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF2F2F7),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          NavItem(
            icon: CupertinoIcons.house,
            activeIcon: CupertinoIcons.house_fill,
            label: l10n.home,
          ),
          NavItem(
            icon: CupertinoIcons.person_2,
            activeIcon: CupertinoIcons.person_2_fill,
            label: l10n.doctorPatientsTab,
          ),
          NavItem(
            icon: CupertinoIcons.doc_text,
            activeIcon: CupertinoIcons.doc_text_fill,
            label: l10n.doctorPrescriptionsTab,
          ),
          NavItem(
            icon: CupertinoIcons.clock,
            activeIcon: CupertinoIcons.clock_fill,
            label: l10n.doctorPrescriptionHistoryTab,
          ),
          NavItem(
            icon: CupertinoIcons.settings,
            activeIcon: CupertinoIcons.settings_solid,
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
