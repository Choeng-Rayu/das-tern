import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/prescription.dart';
import 'package:das_tern_mcp/data/repositories/prescription_repository.dart';

class CreatePrescriptionViewModel extends ChangeNotifier {
  CreatePrescriptionViewModel({required PrescriptionRepository repository})
      : _repository = repository;

  final PrescriptionRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  final int totalSteps = 3;

  String _title = '';
  String get title => _title;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  final List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> get medications =>
      List.unmodifiable(_medications);

  Prescription? _createdPrescription;
  Prescription? get createdPrescription => _createdPrescription;

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setStartDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  void setEndDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  void addMedication(Map<String, dynamic> med) {
    _medications.add(med);
    notifyListeners();
  }

  void removeMedication(int index) {
    if (index >= 0 && index < _medications.length) {
      _medications.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> submitPrescription() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      _createdPrescription = await _repository.createPrescription({
        'title': _title,
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        'medications': _medications,
      });
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to create prescription.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
