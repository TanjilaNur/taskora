/// Base class for typed failures. Subtypes tell callers what went wrong
/// without having to parse raw exception messages.
abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

/// An Isar read / write / delete failed.
class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

/// An image pick, compress, save, or download failed.
class ImageFailure extends AppFailure {
  const ImageFailure(super.message);
}

/// A backup export or import failed.
class BackupFailure extends AppFailure {
  const BackupFailure(super.message);
}

/// User input didn't pass a business rule (e.g. empty title, max depth).
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}