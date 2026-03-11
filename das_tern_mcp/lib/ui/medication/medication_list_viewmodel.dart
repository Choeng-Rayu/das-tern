import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/medication.dart';
import 'package:das_tern_mcp/data/repositories/medication_repository.dart';

class MedicationListViewModel extends ChangeNotifier {
  MedicationListViewModel({
    required MedicationRepository repository,
    required String prescriptionId,
  })  : _repository = repository,
        _prescriptionId = prescriptionId;

  final MedicationRepository _repository;
  final String _prescriptionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  bool get isEmpty => !_isLoading && !_hasError && _medications.isEmpty;

  Future<void> loadMedications() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      _medications = await _repository.getMedications(_prescriptionId);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load medications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
