import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';

class CreateTaskParams {
  final String title;
  final String? description;
  final String? parentId;
  final int depth;
  final DateTime? dueDate;
  final TaskPriority priority;

  const CreateTaskParams({
    required this.title,
    this.description,
    this.parentId,
    this.depth = 1,
    this.dueDate,
    this.priority = TaskPriority.medium,
  });
}

class CreateTaskUseCase {
  final TodoRepository _repository;
  const CreateTaskUseCase(this._repository);

  Future<Result<Task>> call(CreateTaskParams params) async {
    if (params.title.trim().isEmpty) {
      return Err(Exception(const ValidationFailure('Title cannot be empty').message));
    }
    if (params.depth > 4) {
      return Err(Exception(const ValidationFailure('Maximum nesting depth of 4 reached').message));
    }

    final now = DateTime.now();
    final task = Task(
      id: '',
      title: params.title.trim(),
      description: params.description?.trim(),
      parentId: params.parentId,
      depth: params.depth,
      dueDate: params.dueDate,
      priority: params.priority,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createTask(task);
  }
}