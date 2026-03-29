import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

/// Deletes a task and all its descendants (cascade).
class DeleteTaskUseCase {
  final TaskRepository _repository;
  const DeleteTaskUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteTask(id);
}