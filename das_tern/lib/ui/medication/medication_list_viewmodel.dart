import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/medication.dart';
import 'package:das_tern/data/repositories/medication_repository.dart';
import 'package:flutter/foundation.dart';

class MedicationListViewModel extends ChangeNotifier {
  MedicationListViewModel({required MedicationRepository medicationRepository})
    : _medicationRepository = medicationRepository {
    load = Command0(_load);
  }

  final MedicationRepository _medicationRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Medication> _medications = <Medication>[];
  List<Medication> get medications => _medications;

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _medicationRepository.getMedications();
    } catch (_) {
      _errorMessage = 'Unable to load medications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
