import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/prescription.dart';
import 'package:das_tern/data/repositories/prescription_repository.dart';
import 'package:flutter/foundation.dart';

class PrescriptionDetailViewModel extends ChangeNotifier {
  PrescriptionDetailViewModel({required PrescriptionRepository repository})
    : _repository = repository {
    load = Command0(_load);
  }

  final PrescriptionRepository _repository;

  late final Command0 load;

  String? _prescriptionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Prescription? _prescription;
  Prescription? get prescription => _prescription;

  void setPrescriptionId(String id) {
    if (_prescriptionId == id) {
      return;
    }
    _prescriptionId = id;
    load.execute();
  }

  Future<void> _load() async {
    if (_prescriptionId == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prescription = await _repository.getPrescriptionById(_prescriptionId!);
      if (_prescription == null) {
        _errorMessage = 'Prescription not found';
      }
    } catch (_) {
      _errorMessage = 'Unable to load prescription details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
