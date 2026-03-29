import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

/// Toggles a task's completion and propagates the change up the tree.
class ToggleCompletionUseCase {
  final TaskRepository _repository;
  const ToggleCompletionUseCase(this._repository);

  Future<Result<Task>> call(String id) => _repository.toggleCompletion(id);
}