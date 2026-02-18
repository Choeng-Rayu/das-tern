import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common_widgets.dart';
import 'doctor_home_tab.dart';
import 'doctor_patients_tab.dart';
import 'doctor_prescriptions_tab.dart';
import 'doctor_prescription_history_tab.dart';
import 'doctor_settings_tab.dart';

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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: l10n.home,
          ),
          AppNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: l10n.doctorPatientsTab,
          ),
          AppNavItem(
            icon: Icons.note_add_outlined,
            activeIcon: Icons.note_add,
            label: l10n.doctorPrescriptionsTab,
          ),
          AppNavItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: l10n.doctorPrescriptionHistoryTab,
          ),
          AppNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
