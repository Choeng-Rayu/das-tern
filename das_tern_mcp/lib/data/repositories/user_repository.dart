/// Repository for user profile operations.
///
/// Wraps [ApiService] user endpoints and returns typed results.
library;

import '../../domain/models/user_models.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';

// ─── Result type ────────────────────────────────────────────────────────────

sealed class UserResult<T> {
  const UserResult();
}

class UserSuccess<T> extends UserResult<T> {
  const UserSuccess(this.data);
  final T data;
}

class UserFailure<T> extends UserResult<T> {
  const UserFailure(this.message);
  final String message;
}

// ─── Repository ─────────────────────────────────────────────────────────────

class UserRepository {
  UserRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;
  final LoggerService _log = LoggerService.instance;

  /// Fetch the authenticated user's profile.
  Future<UserResult<CurrentUser>> getMyProfile() async {
    try {
      final json = await _api.getMyProfile();
      return UserSuccess(CurrentUser.fromJson(json));
    } catch (e) {
      _log.error('UserRepository', 'getMyProfile failed', e);
      return UserFailure(_errorMessage(e));
    }
  }

  /// Update the authenticated user's profile.
  Future<UserResult<CurrentUser>> updateProfile(
    UserProfileUpdate update,
  ) async {
    if (update.isEmpty) {
      return const UserFailure('No changes to save');
    }
    try {
      final json = await _api.updateProfile(update.toJson());
      return UserSuccess(CurrentUser.fromJson(json));
    } catch (e) {
      _log.error('UserRepository', 'updateProfile failed', e);
      return UserFailure(_errorMessage(e));
    }
  }

  String _errorMessage(Object e) {
    return e
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}
