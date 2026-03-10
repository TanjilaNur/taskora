import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

class ToggleCompletionUseCase {
  final TodoRepository _repository;
  const ToggleCompletionUseCase(this._repository);

  Future<Result<Task>> call(String id) =>
      _repository.toggleCompletion(id);
}