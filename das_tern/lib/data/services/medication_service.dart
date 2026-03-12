import 'dart:async';

import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/medication.dart';

abstract class MedicationService {
  Future<List<Medication>> fetchMedications();
}

class MockMedicationService implements MedicationService {
  @override
  Future<List<Medication>> fetchMedications() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      Medication(
        id: 'med-1',
        name: 'Metformin',
        dosage: 500,
        unit: 'mg',
        frequency: '2 times/day',
        medicineType: MedicineType.po,
        medicineUnit: MedicineUnit.tablet,
        description: 'For blood sugar control',
      ),
      Medication(
        id: 'med-2',
        name: 'Amlodipine',
        dosage: 5,
        unit: 'mg',
        frequency: '1 time/day',
        medicineType: MedicineType.oral,
        medicineUnit: MedicineUnit.tablet,
        description: 'For blood pressure control',
      ),
    ];
  }
}
