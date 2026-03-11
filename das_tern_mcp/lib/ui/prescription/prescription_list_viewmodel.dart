import 'package:flutter/foundation.dart';

import 'package:das_tern_mcp/data/models/prescription.dart';
import 'package:das_tern_mcp/data/repositories/prescription_repository.dart';

/// ViewModel for the Prescription List screen.
class PrescriptionListViewModel extends ChangeNotifier {
  PrescriptionListViewModel({required PrescriptionRepository repository})
      : _repository = repository;

  final PrescriptionRepository _repository;

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Prescription> _prescriptions = [];
  List<Prescription> get prescriptions => _prescriptions;

  bool get isEmpty => !_isLoading && !_hasError && _prescriptions.isEmpty;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads all prescriptions for the current user.
  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _prescriptions = await _repository.getPrescriptions();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load prescriptions. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes the prescription with [id] and refreshes the list.
  Future<void> deletePrescription(String id) async {
    try {
      await _repository.deletePrescription(id);
      _prescriptions = _prescriptions.where((p) => p.id != id).toList();
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete prescription.';
      notifyListeners();
    }
  }
}
