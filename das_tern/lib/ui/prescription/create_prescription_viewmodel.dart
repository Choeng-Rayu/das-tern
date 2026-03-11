import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/medication.dart';
import 'package:das_tern/data/models/prescription.dart';
import 'package:das_tern/data/repositories/prescription_repository.dart';
import 'package:flutter/foundation.dart';

class CreatePrescriptionViewModel extends ChangeNotifier {
  CreatePrescriptionViewModel({required PrescriptionRepository repository})
    : _repository = repository {
    load = Command0(_load);
  }

  final PrescriptionRepository _repository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _created = false;
  bool get created => _created;

  Future<void> _load() async {
    _isLoading = false;
    _errorMessage = null;
    _created = false;
    notifyListeners();
  }

  Future<void> createSamplePrescription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Prescription payload = Prescription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: 'user-1',
        doctorName: 'Dr. Chan',
        medications: const <Medication>[
          Medication(
            id: 'new-med-1',
            name: 'Amoxicillin',
            dosage: 250,
            unit: 'mg',
            frequency: '3 times/day',
          ),
        ],
        issuedAt: DateTime.now(),
        notes: 'Mock created from migration screen',
      );

      await _repository.createPrescription(payload);
      _created = true;
    } catch (_) {
      _errorMessage = 'Unable to create prescription';
      _created = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
