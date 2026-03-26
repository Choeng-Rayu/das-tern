/// Example integration of Health Loading Indicators into existing screens.
///
/// This file demonstrates how to use the loading system in various scenarios
/// throughout the DasTern app.
library;

import 'package:flutter/material.dart';
import 'health_loading_indicator.dart';
import '../../../services/loading_overlay_service.dart';

/// Example 1: Loading in a stateful widget with data fetching
class MedicationListExample extends StatefulWidget {
  const MedicationListExample({super.key});

  @override
  State<MedicationListExample> createState() => _MedicationListExampleState();
}

class _MedicationListExampleState extends State<MedicationListExample> {
  bool _isLoading = false;
  List<String> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _medications = ['Aspirin', 'Ibuprofen', 'Paracetamol'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: _isLoading
          ? const Center(
              child: HealthLoadingIndicator(
                variant: HealthLoadingVariant.pills,
                size: HealthLoadingSize.large,
                message: 'Loading medications...',
              ),
            )
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_medications[index]));
              },
            ),
    );
  }
}

/// Example 2: Using the loading service for form submission
class PrescriptionFormExample extends StatefulWidget {
  const PrescriptionFormExample({super.key});

  @override
  State<PrescriptionFormExample> createState() =>
      _PrescriptionFormExampleState();
}

class _PrescriptionFormExampleState extends State<PrescriptionFormExample> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading overlay while submitting
    await LoadingOverlayService.showWhile(
      context,
      future: _savePrescription(),
      variant: HealthLoadingVariant.medicalCross,
      message: 'Saving prescription...',
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _savePrescription() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Prescription')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Form fields here...
            ElevatedButton(
              onPressed: _submitPrescription,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: Using FutureBuilder with loading indicator
class PatientProfileExample extends StatelessWidget {
  final String patientId;

  const PatientProfileExample({super.key, required this.patientId});

  Future<Map<String, dynamic>> _loadPatientData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    return {'name': 'John Doe', 'age': 35, 'medications': 5};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPatientData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: HealthLoadingIndicator(
                variant: HealthLoadingVariant.heartbeat,
                size: HealthLoadingSize.large,
                message: 'Loading patient data...',
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Name: ${data['name']}'),
              Text('Age: ${data['age']}'),
              Text('Medications: ${data['medications']}'),
            ],
          );
        },
      ),
    );
  }
}

/// Example 4: Inline loading in a button
class RefreshButtonExample extends StatefulWidget {
  const RefreshButtonExample({super.key});

  @override
  State<RefreshButtonExample> createState() => _RefreshButtonExampleState();
}

class _RefreshButtonExampleState extends State<RefreshButtonExample> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isRefreshing ? null : _refresh,
      child: _isRefreshing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: HealthLoadingIndicator.inline(
                variant: HealthLoadingVariant.progressRing,
                size: HealthLoadingSize.small,
              ),
            )
          : const Text('Refresh'),
    );
  }
}

/// Example 5: Using the service with manual control
class UploadPrescriptionExample extends StatelessWidget {
  const UploadPrescriptionExample({super.key});

  Future<void> _uploadFile(BuildContext context) async {
    // Show loading
    LoadingOverlayService.show(
      context,
      variant: HealthLoadingVariant.progressRing,
      message: 'Uploading prescription...',
    );

    try {
      // Simulate upload
      await Future.delayed(const Duration(seconds: 3));

      // Hide loading
      LoadingOverlayService.hide();

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
      }
    } catch (e) {
      // Hide loading on error
      LoadingOverlayService.hide();

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _uploadFile(context),
      child: const Text('Upload Prescription'),
    );
  }
}

/// Example 6: Pull-to-refresh with loading indicator
class MedicationFeedExample extends StatefulWidget {
  const MedicationFeedExample({super.key});

  @override
  State<MedicationFeedExample> createState() => _MedicationFeedExampleState();
}

class _MedicationFeedExampleState extends State<MedicationFeedExample> {
  final List<String> _items = ['Item 1', 'Item 2', 'Item 3'];

  Future<void> _refresh() async {
    // Show inline loading at top
    setState(() => _items.insert(0, 'Loading...'));

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 2));

    // Update with new data
    setState(() {
      _items.removeAt(0);
      _items.insert(0, 'New Item ${DateTime.now().second}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          if (item == 'Loading...') {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: HealthLoadingIndicator(
                  variant: HealthLoadingVariant.pills,
                  size: HealthLoadingSize.medium,
                ),
              ),
            );
          }

          return ListTile(title: Text(item));
        },
      ),
    );
  }
}

/// Example 7: Conditional loading based on network state
class NetworkAwareExample extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final Widget? child;

  const NetworkAwareExample({
    super.key,
    required this.isOnline,
    required this.isLoading,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No internet connection'),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: HealthLoadingIndicator(
          variant: HealthLoadingVariant.heartbeat,
          size: HealthLoadingSize.large,
          message: 'Syncing data...',
        ),
      );
    }

    return child ?? const SizedBox.shrink();
  }
}
