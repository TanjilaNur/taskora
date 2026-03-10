import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

class GetRootTasksUseCase {
  final TodoRepository _repository;
  const GetRootTasksUseCase(this._repository);

  Future<Result<List<Task>>> call() => _repository.getRootTasks();
}