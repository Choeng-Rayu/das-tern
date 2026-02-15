import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.homeTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medication_outlined),
            activeIcon: const Icon(Icons.medication),
            label: l10n.medicationsAnalysis,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.document_scanner_outlined),
            activeIcon: const Icon(Icons.document_scanner),
            label: l10n.scanPrescriptionTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.family_restroom_outlined),
            activeIcon: const Icon(Icons.family_restroom),
            label: l10n.familyFeatures,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
