import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/prescription.dart';
import 'package:das_tern_mcp/data/repositories/prescription_repository.dart';

class PrescriptionDetailViewModel extends ChangeNotifier {
  PrescriptionDetailViewModel({
    required PrescriptionRepository repository,
    required String prescriptionId,
  })  : _repository = repository,
        _prescriptionId = prescriptionId;

  final PrescriptionRepository _repository;
  final String _prescriptionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Prescription? _prescription;
  Prescription? get prescription => _prescription;

  Future<void> loadPrescription() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      _prescription = await _repository.getPrescription(_prescriptionId);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load prescription.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
