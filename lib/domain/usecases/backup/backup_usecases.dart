import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

/// Serialises all tasks to JSON bytes for sharing as a backup file.
class ExportBackupUseCase {
  final TaskRepository _repository;
  const ExportBackupUseCase(this._repository);

  Future<Result<List<int>>> call() => _repository.exportBackup();
}

/// Replaces all existing tasks with data imported from backup bytes.
class ImportBackupUseCase {
  final TaskRepository _repository;
  const ImportBackupUseCase(this._repository);

  Future<Result<void>> call(List<int> bytes) => _repository.importBackup(bytes);
}