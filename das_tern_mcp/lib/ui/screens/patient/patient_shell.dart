import 'package:flutter/material.dart';
import '../../../ui/theme/app_colors.dart';
import 'patient_home_tab.dart';
import 'patient_medications_tab.dart';
import 'patient_scan_tab.dart';
import 'patient_family_tab.dart';
import 'patient_settings_tab.dart';

/// Patient dashboard shell with 5-tab bottom navigation.
/// Figma tabs: ទំព័រដើម | ការវិភាគថ្នាំ | ស្កេនវេជ្ជបញ្ជា | មុខងារគ្រួសារ | ការកំណត់
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;

  final _tabs = const [
    PatientHomeTab(),
    PatientMedicationsTab(),
    PatientScanTab(),
    PatientFamilyTab(),
    PatientSettingsTab(),
  ];

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
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'ការវិភាគថ្នាំ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner),
            label: 'ស្កេនវេជ្ជបញ្ជា',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_outlined),
            activeIcon: Icon(Icons.family_restroom),
            label: 'មុខងារគ្រួសារ',
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
