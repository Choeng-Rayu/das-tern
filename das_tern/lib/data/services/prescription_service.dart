import 'dart:async';

import 'package:das_tern/data/models/medication.dart';
import 'package:das_tern/data/models/prescription.dart';

abstract class PrescriptionService {
  Future<List<Prescription>> fetchPrescriptions();
  Future<Prescription?> fetchPrescriptionById(String id);
  Future<Prescription> createPrescription(Prescription prescription);
}

class MockPrescriptionService implements PrescriptionService {
  final List<Prescription> _items = <Prescription>[
    Prescription(
      id: 'rx-1',
      patientId: 'user-1',
      doctorName: 'Dr. Chan',
      medications: const <Medication>[
        Medication(
          id: 'med-1',
          name: 'Metformin',
          dosage: 500,
          unit: 'mg',
          frequency: '2 times/day',
        ),
      ],
      issuedAt: DateTime(2026, 3, 10),
      notes: 'Take after meal',
    ),
  ];

  @override
  Future<List<Prescription>> fetchPrescriptions() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<Prescription>.unmodifiable(_items);
  }

  @override
  Future<Prescription?> fetchPrescriptionById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (final Prescription item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<Prescription> createPrescription(Prescription prescription) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    _items.insert(0, prescription);
    return prescription;
  }
}
