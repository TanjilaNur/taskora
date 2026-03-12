import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

class ExportBackupUseCase {
  final TaskRepository _repository;
  const ExportBackupUseCase(this._repository);

  Future<Result<List<int>>> call() => _repository.exportBackup();
}

class ImportBackupUseCase {
  final TaskRepository _repository;
  const ImportBackupUseCase(this._repository);

  Future<Result<void>> call(List<int> bytes) =>
      _repository.importBackup(bytes);
}