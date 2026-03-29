import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';

/// Updates the manual completion % on a leaf task. Clamps value to 0–100.
class UpdateCompletionPercentUseCase {
  final TaskRepository _repository;
  const UpdateCompletionPercentUseCase(this._repository);

  Future<Result<Task>> call(String id, double percent) =>
      _repository.updateCompletionPercent(id, percent.clamp(0.0, 100.0));
}