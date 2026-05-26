import 'package:flutter/foundation.dart';

import 'package:das_tern_mcp/data/models/user.dart';
import 'package:das_tern_mcp/data/repositories/auth_repository.dart';

/// ViewModel for the Settings screen.
///
/// Manages current user state, theme toggle, language selection, and logout.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required AuthRepository authRepository,
    bool isDarkMode = false,
    String language = 'en',
  })  : _authRepo = authRepository,
        _isDarkMode = isDarkMode,
        _language = language;

  final AuthRepository _authRepo;

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  String _language;
  String get language => _language;

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Loads the current user profile from the repository.
  Future<void> loadSettings() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepo.getCurrentUser();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load settings. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles between light and dark theme.
  ///
  /// The caller is responsible for persisting the preference via ThemeProvider.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Changes the app language.
  ///
  /// The caller is responsible for persisting via LocaleProvider.
  void changeLanguage(String languageCode) {
    _language = languageCode;
    notifyListeners();
  }

  /// Signs out the current user.
  ///
  /// Clears the in-memory cache via [AuthRepository.logout].
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepo.logout();
      _currentUser = null;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Logout failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
