/// A sealed result type for safe error handling across layers.
sealed class Result<T> {
  const Result();
}

/// Represents a successful result with a value.
class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

/// Represents a failed result with an error.
class Error<T> extends Result<T> {
  const Error(this.error);
  final Exception error;
}
