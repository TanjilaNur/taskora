abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

class ImageFailure extends AppFailure {
  const ImageFailure(super.message);
}

class BackupFailure extends AppFailure {
  const BackupFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}