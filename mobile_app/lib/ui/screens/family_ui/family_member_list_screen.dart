import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class FamilyMemberListScreen extends StatelessWidget {
  const FamilyMemberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text('Family Members', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}
