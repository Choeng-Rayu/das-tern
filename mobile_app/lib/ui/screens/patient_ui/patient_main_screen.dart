import 'package:flutter/material.dart';
import '../../widgets/patient_bottom_nav.dart';
import 'patient_dashboard_screen.dart';
import 'medication_analysis_screen.dart';
import 'prescription_scan_screen.dart';
import 'family_features_screen.dart';
import 'settings_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PatientDashboardScreen(),
    MedicationAnalysisScreen(),
    PrescriptionScanScreen(),
    FamilyFeaturesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: PatientBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
