import 'package:das_tern/data/models/prescription.dart';
import 'package:das_tern/data/services/prescription_service.dart';

abstract class PrescriptionRepository {
  Future<List<Prescription>> getPrescriptions();
  Future<Prescription?> getPrescriptionById(String id);
  Future<Prescription> createPrescription(Prescription prescription);
}

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl({required PrescriptionService service})
    : _service = service;

  final PrescriptionService _service;

  @override
  Future<List<Prescription>> getPrescriptions() {
    return _service.fetchPrescriptions();
  }

  @override
  Future<Prescription?> getPrescriptionById(String id) {
    return _service.fetchPrescriptionById(id);
  }

  @override
  Future<Prescription> createPrescription(Prescription prescription) {
    return _service.createPrescription(prescription);
  }
}
