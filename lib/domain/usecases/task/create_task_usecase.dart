import '../../entities/task.dart';
import '../../repositories/task_manager_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';

/// Input data for creating a task. Depth defaults to 1 (root level).
class CreateTaskParams {
  final String title;
  final String? description;
  final String? parentId;
  final int depth;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String? imagePath;
  final String? imageUrl;

  const CreateTaskParams({
    required this.title,
    this.description,
    this.parentId,
    this.depth = 1,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.imagePath,
    this.imageUrl,
  });
}

/// Validates input then delegates to the repository to persist the task.
class CreateTaskUseCase {
  final TaskRepository _repository;
  const CreateTaskUseCase(this._repository);

  Future<Result<Task>> call(CreateTaskParams params) async {
    // Guard: title must not be blank
    if (params.title.trim().isEmpty) {
      return Err(Exception(const ValidationFailure('Title cannot be empty').message));
    }
    // Guard: respect the max nesting depth
    if (params.depth > 4) {
      return Err(Exception(const ValidationFailure('Maximum nesting depth of 4 reached').message));
    }

    final now  = DateTime.now();
    final task = Task(
      id: '',   // repository assigns the real UUID
      title: params.title.trim(),
      description: params.description?.trim(),
      parentId: params.parentId,
      depth: params.depth,
      dueDate: params.dueDate,
      priority: params.priority,
      imagePath: params.imagePath,
      imageUrl: params.imageUrl,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createTask(task);
  }
}