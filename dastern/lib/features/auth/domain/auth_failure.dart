/// Auth-specific failures. Sealed so the UI can exhaustively switch on them.
sealed class AuthFailure implements Exception {
  const AuthFailure({required this.message, this.cause});
  final String message;
  final Object? cause;

  const factory AuthFailure.invalidCredential() = _InvalidCredential;
  const factory AuthFailure.cancelled() = _Cancelled;
  const factory AuthFailure.invalidProviderResponse() = _InvalidProviderResponse;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.wrongPassword() = _WrongPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.serverError(String? detail) = _ServerError;

  @override
  String toString() => '$runtimeType($message)';
}

final class _InvalidCredential extends AuthFailure {
  const _InvalidCredential() : super(message: 'errorsInvalidCredential');
}

final class _Cancelled extends AuthFailure {
  const _Cancelled() : super(message: 'errorsCancelled');
}

final class _InvalidProviderResponse extends AuthFailure {
  const _InvalidProviderResponse()
      : super(message: 'errorsInvalidProviderResponse');
}

final class _WeakPassword extends AuthFailure {
  const _WeakPassword() : super(message: 'errorsWeakPassword');
}

final class _EmailAlreadyInUse extends AuthFailure {
  const _EmailAlreadyInUse() : super(message: 'errorsEmailAlreadyInUse');
}

final class _WrongPassword extends AuthFailure {
  const _WrongPassword() : super(message: 'errorsWrongPassword');
}

final class _UserNotFound extends AuthFailure {
  const _UserNotFound() : super(message: 'errorsUserNotFound');
}

final class _ServerError extends AuthFailure {
  const _ServerError(String? detail)
      : super(message: 'errorsServerError', cause: detail);
}
