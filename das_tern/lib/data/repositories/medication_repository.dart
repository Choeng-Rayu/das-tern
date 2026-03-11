import 'package:das_tern/data/models/medication.dart';
import 'package:das_tern/data/services/medication_service.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getMedications();
}

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl({required MedicationService service})
    : _service = service;

  final MedicationService _service;

  @override
  Future<List<Medication>> getMedications() {
    return _service.fetchMedications();
  }
}
