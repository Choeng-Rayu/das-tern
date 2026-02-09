import 'package:flutter/material.dart';
import '../models/prescription_model/prescription.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

/// Manages prescription state with offline cache fallback.
class PrescriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  bool _isLoading = false;
  String? _error;
  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;

  int get activePrescriptionCount =>
      _prescriptions.where((p) => p.status == 'ACTIVE').length;

  /// Fetch prescriptions. Online → API + cache. Offline → SQLite.
  Future<void> fetchPrescriptions({String? status, String? patientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_sync.isOnline) {
        final result = await _api.getPrescriptions(
          status: status,
          patientId: patientId,
        );
        _prescriptions =
            result.map((p) => Prescription.fromJson(p)).toList();
        // Cache for offline
        await _db.cachePrescriptions(
            result.map((p) => Map<String, dynamic>.from(p)).toList());
      } else {
        // Offline fallback
        final cached = await _db.getCachedPrescriptions();
        _prescriptions =
            cached.map((p) => Prescription.fromJson(p)).toList();
        if (status != null) {
          _prescriptions =
              _prescriptions.where((p) => p.status == status).toList();
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Fallback to cache on API error
      try {
        final cached = await _db.getCachedPrescriptions();
        if (cached.isNotEmpty) {
          _prescriptions =
              cached.map((p) => Prescription.fromJson(p)).toList();
          _error = null;
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch single prescription details.
  Future<void> fetchPrescription(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getPrescription(id);
      _selectedPrescription = Prescription.fromJson(result);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new prescription (doctor only).
  Future<bool> createPrescription(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.createPrescription(data);
      await fetchPrescriptions(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing prescription (PATCH).
  Future<bool> updatePrescription(
      String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updatePrescription(id, data);
      await fetchPrescriptions();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm a prescription.
  Future<bool> confirmPrescription(String id) async {
    try {
      await _api.confirmPrescription(id);
      await fetchPrescriptions();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
