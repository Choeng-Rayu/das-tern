import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common_widgets.dart';
import 'tab/patient_home_tab.dart';
import 'tab/patient_medications_tab.dart';
import 'tab/patient_scan_tab.dart';
import 'tab/patient_family_tab.dart';
import 'tab/patient_settings_tab.dart';

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
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: l10n.homeTab,
          ),
          AppNavItem(
            icon: Icons.medication_outlined,
            activeIcon: Icons.medication,
            label: l10n.medicationsAnalysis,
          ),
          AppNavItem(
            icon: Icons.document_scanner_outlined,
            activeIcon: Icons.document_scanner,
            label: l10n.scanPrescriptionTab,
          ),
          AppNavItem(
            icon: Icons.family_restroom_outlined,
            activeIcon: Icons.family_restroom,
            label: l10n.familyFeatures,
          ),
          AppNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
