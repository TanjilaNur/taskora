import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';

/// Validates the title then saves the updated task with a fresh [updatedAt].
class UpdateTaskUseCase {
  final TaskRepository _repository;
  const UpdateTaskUseCase(this._repository);

  Future<Result<Task>> call(Task task) async {
    if (task.title.trim().isEmpty) {
      return Err(Exception(const ValidationFailure('Title cannot be empty').message));
    }
    return _repository.updateTask(task.copyWith(updatedAt: DateTime.now()));
  }
}
