import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

/// Fetches all root-level tasks with their full subtree.
class GetRootTasksUseCase {
  final TaskRepository _repository;
  const GetRootTasksUseCase(this._repository);

  Future<Result<List<Task>>> call() => _repository.getRootTasks();
}