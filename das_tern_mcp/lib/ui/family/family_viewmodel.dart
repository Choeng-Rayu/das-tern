import 'package:flutter/foundation.dart';

class FamilyViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _connections = [];
  List<dynamic> get connections => _connections;

  Future<void> loadConnections() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      // Placeholder — wire a FamilyRepository when available.
      await Future.delayed(const Duration(milliseconds: 300));
      _connections = [];
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load connections.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
