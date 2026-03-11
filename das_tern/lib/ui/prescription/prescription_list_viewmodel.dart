import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/prescription.dart';
import 'package:das_tern/data/repositories/prescription_repository.dart';
import 'package:flutter/foundation.dart';

class PrescriptionListViewModel extends ChangeNotifier {
  PrescriptionListViewModel({required PrescriptionRepository repository})
    : _repository = repository {
    load = Command0(_load);
  }

  final PrescriptionRepository _repository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Prescription> _prescriptions = <Prescription>[];
  List<Prescription> get prescriptions => _prescriptions;

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prescriptions = await _repository.getPrescriptions();
    } catch (_) {
      _errorMessage = 'Unable to load prescriptions';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
