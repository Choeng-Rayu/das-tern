import 'package:flutter/material.dart';
import '../models/connection_model/connection.dart';
import '../services/api_service.dart';

/// Manages family connections, tokens, nudges, and caregiver access.
class ConnectionProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  List<Connection> _connections = [];
  List<Connection> _caregivers = [];
  List<Connection> _connectedPatients = [];
  Map<String, dynamic>? _caregiverLimit;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Connection> get connections => _connections;
  List<Connection> get caregivers => _caregivers;
  List<Connection> get connectedPatients => _connectedPatients;
  Map<String, dynamic>? get caregiverLimit => _caregiverLimit;

  List<Connection> get pendingConnections =>
      _connections.where((c) => c.status.name == 'pending').toList();
  List<Connection> get acceptedConnections =>
      _connections.where((c) => c.status.name == 'accepted').toList();

  // ── Basic Connections ──

  /// Fetch connections with optional status filter.
  Future<void> fetchConnections({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getConnections(status: status);
      _connections = result.map((c) => Connection.fromJson(c)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a connection request (patient → doctor).
  Future<bool> sendRequest(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.createConnection(data);
      await fetchConnections();
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

  /// Accept a connection (doctor accepting patient request).
  Future<bool> acceptConnection(String id, Map<String, dynamic> permissions) async {
    try {
      await _api.acceptConnection(id, permissions);
      await fetchConnections();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Revoke a connection.
  Future<bool> revokeConnection(String id) async {
    try {
      await _api.revokeConnection(id);
      await fetchConnections();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Token Operations ──

  /// Generate a connection token (patient side).
  Future<Map<String, dynamic>?> generateToken(String permissionLevel) async {
    _error = null;
    try {
      final result = await _api.generateConnectionToken(permissionLevel);
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Validate a connection token (caregiver side).
  Future<Map<String, dynamic>?> validateToken(String token) async {
    _error = null;
    try {
      final result = await _api.validateConnectionToken(token);
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Consume a token to create a connection (caregiver side).
  Future<bool> consumeToken(String token) async {
    _error = null;
    try {
      await _api.consumeConnectionToken(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Family Members ──

  /// Fetch caregivers for the current patient.
  Future<void> fetchCaregivers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getCaregivers();
      _caregivers = result.map((c) => Connection.fromJson(c)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch patients connected to the current caregiver.
  Future<void> fetchConnectedPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getConnectedPatients();
      _connectedPatients =
          result.map((c) => Connection.fromJson(c)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle alerts on/off for a connection.
  Future<bool> toggleAlerts(String connectionId, bool enabled) async {
    try {
      await _api.toggleConnectionAlerts(connectionId, enabled);
      // Update local state
      _updateConnectionAlerts(connectionId, enabled);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _updateConnectionAlerts(String connectionId, bool enabled) {
    // Refresh the lists to get updated data
    fetchCaregivers();
    fetchConnectedPatients();
  }

  /// Fetch caregiver limit for subscription tier.
  Future<void> fetchCaregiverLimit() async {
    try {
      _caregiverLimit = await _api.getCaregiverLimit();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Nudge Operations ──

  /// Send a nudge to a patient.
  Future<bool> sendNudge(String patientId, String? doseId) async {
    _error = null;
    try {
      await _api.sendNudge(patientId, doseId ?? '');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Respond to a nudge.
  Future<bool> respondToNudge(
    String caregiverId,
    String doseId,
    String response,
  ) async {
    _error = null;
    try {
      await _api.respondToNudge(caregiverId, doseId, response);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Grace Period ──

  /// Update grace period setting.
  Future<bool> updateGracePeriod(int minutes) async {
    _error = null;
    try {
      await _api.updateGracePeriod(minutes);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Connection History ──

  /// Get connection history with optional filter.
  Future<List<Map<String, dynamic>>> getConnectionHistory({
    String? filter,
  }) async {
    try {
      final result = await _api.getConnectionHistory(filter: filter);
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return [];
    }
  }
}
