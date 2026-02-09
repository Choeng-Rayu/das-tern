import 'package:flutter/material.dart';
import '../models/connection_model/connection.dart';
import '../services/api_service.dart';

/// Manages doctor-patient connections.
class ConnectionProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  List<Connection> _connections = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Connection> get connections => _connections;

  List<Connection> get pendingConnections =>
      _connections.where((c) => c.status.name == 'pending').toList();
  List<Connection> get acceptedConnections =>
      _connections.where((c) => c.status.name == 'accepted').toList();

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
}
