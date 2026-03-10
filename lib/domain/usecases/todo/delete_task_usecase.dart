import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

class DeleteTaskUseCase {
  final TodoRepository _repository;
  const DeleteTaskUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteTask(id);
}