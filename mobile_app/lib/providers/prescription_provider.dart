import 'package:flutter/foundation.dart';
import '../models/prescription_model/prescription.dart';
import '../services/api_service.dart';

class PrescriptionProvider extends ChangeNotifier {
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Prescription> get activePrescriptions =>
      _prescriptions.where((p) => p.status == 'ACTIVE').toList();

  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.instance.getPrescriptions();
      _prescriptions = data.map((json) => Prescription.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Prescription?> createPrescription(Prescription prescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.instance.createPrescription(prescription.toJson());
      final created = Prescription.fromJson(data);
      _prescriptions.add(created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<Prescription?> confirmPrescription(String id) async {
    try {
      final data = await ApiService.instance.confirmPrescription(id);
      final confirmed = Prescription.fromJson(data);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = confirmed;
        notifyListeners();
      }
      return confirmed;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Prescription?> updatePrescription(String id, Map<String, dynamic> data) async {
    try {
      final result = await ApiService.instance.updatePrescription(id, data);
      final updated = Prescription.fromJson(result);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
