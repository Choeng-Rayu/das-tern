import 'package:flutter/material.dart';
import '../../widgets/doctor_bottom_nav.dart';
import 'doctor_dashboard_screen.dart';
import 'patient_monitoring_screen.dart';
import 'create_prescription_screen.dart';
import 'prescription_history_screen.dart';
import '../patient_ui/settings_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DoctorDashboardScreen(),
    PatientMonitoringScreen(),
    CreatePrescriptionScreen(),
    PrescriptionHistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: DoctorBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
