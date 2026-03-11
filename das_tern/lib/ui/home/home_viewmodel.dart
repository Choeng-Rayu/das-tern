import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/repositories/medication_repository.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required MedicationRepository medicationRepository})
    : _medicationRepository = medicationRepository {
    load = Command0(_load);
  }

  final MedicationRepository _medicationRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _medicationCount = 0;
  int get medicationCount => _medicationCount;

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final medications = await _medicationRepository.getMedications();
      _medicationCount = medications.length;
    } catch (_) {
      _errorMessage = 'Unable to load home data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
