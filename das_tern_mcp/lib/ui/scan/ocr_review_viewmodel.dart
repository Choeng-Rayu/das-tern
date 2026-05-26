import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/medication.dart';
import 'package:das_tern_mcp/data/repositories/medication_repository.dart';

class OcrReviewViewModel extends ChangeNotifier {
  OcrReviewViewModel({
    required MedicationRepository repository,
    required List<Medication> medications,
    required String ocrText,
  })  : _repository = repository,
        _medications = List.of(medications),
        _ocrText = ocrText;

  final MedicationRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  bool _saved = false;
  bool get saved => _saved;

  List<Medication> _medications;
  List<Medication> get medications => List.unmodifiable(_medications);

  final String _ocrText;
  String get ocrText => _ocrText;

  Future<void> confirmAndSave(String prescriptionId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      for (final med in _medications) {
        await _repository.addMedication(prescriptionId, med.toJson());
      }
      _saved = true;
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
