/// Project-wide failure type used by repositories and use cases.
///
/// All UI surfaces consume `Result`-style values whose error variant is an
/// [AppFailure] — never raw exceptions. This keeps error handling exhaustive
/// (sealed subclasses) and makes localisation straightforward (each subclass
/// maps to one or two ARB keys).
///
/// When a feature spec is implemented, prefer a domain-specific failure
/// (e.g., `PrescriptionFailure`) that extends [AppFailure] over reaching
/// for [AppFailure.unknown].
///
/// Spec ref: 00-overview §Requirement 4 (data flow).
sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.cause, this.stackTrace});

  /// User-facing message key (matches an ARB entry under `errors*`).
  final String message;

  /// Underlying exception/error if one was caught.
  final Object? cause;

  /// Stack trace when the failure was caught.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({super.cause, super.stackTrace})
    : super(message: 'errorsNetwork');
}

class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure({super.cause, super.stackTrace})
    : super(message: 'errorsPermissionDenied');
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({super.cause, super.stackTrace})
    : super(message: 'errorsUnknown');
}
