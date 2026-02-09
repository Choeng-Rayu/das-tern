import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class PrescriptionHistoryScreen extends StatelessWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text('Prescription History', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}
