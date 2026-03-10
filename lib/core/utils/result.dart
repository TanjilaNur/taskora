/// A simple Result type that represents either success [Ok] or failure [Err].
/// This avoids throwing exceptions across layer boundaries.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get value => (this as Ok<T>).data;
  Exception get error => (this as Err<T>).exception;

  R fold<R>({
    required R Function(T data) ok,
    required R Function(Exception error) err,
  }) {
    return switch (this) {
      Ok<T>(data: final d) => ok(d),
      Err<T>(exception: final e) => err(e),
    };
  }
}

final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

final class Err<T> extends Result<T> {
  final Exception exception;
  const Err(this.exception);
}