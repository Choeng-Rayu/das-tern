import 'package:flutter/material.dart';
import '../../../ui/theme/app_colors.dart';
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.neutral400,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ទំព័រដើម',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'តាមដានអ្នកជំងឺ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add_outlined),
            activeIcon: Icon(Icons.note_add),
            label: 'បង្កើតវេជ្ជបញ្ជា',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'ប្រវិត្តវេជ្ជបញ្ជារ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'ការកំណត់',
          ),
        ],
      ),
    );
  }
}
