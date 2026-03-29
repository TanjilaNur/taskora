/// Every use case / repository returns either [Ok] or [Err].
/// This forces callers to handle both outcomes — no silent failures.
///
/// Example:
/// ```dart
/// result.fold(ok: (data) => ..., err: (e) => ...);
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk  => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T         get value => (this as Ok<T>).data;
  Exception get error => (this as Err<T>).exception;

  /// Run [ok] on success or [err] on failure.
  R fold<R>({
    required R Function(T data)      ok,
    required R Function(Exception error) err,
  }) {
    return switch (this) {
      Ok<T>(data: final d)      => ok(d),
      Err<T>(exception: final e) => err(e),
    };
  }
}

/// Wraps a successful value.
final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

/// Wraps a failure with its exception.
final class Err<T> extends Result<T> {
  final Exception exception;
  const Err(this.exception);
}