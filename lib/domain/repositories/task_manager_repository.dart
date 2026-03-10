import '../entities/task.dart';
import '../../core/utils/result.dart';

/// Abstract contract. The domain layer depends only on this interface,
/// never on the concrete Isar implementation.
abstract interface class TodoRepository {
  /// Fetch all root-level tasks (parentId == null) with full subtask trees.
  Future<Result<List<Task>>> getRootTasks();

  /// Fetch a single task with its full subtask tree by id.
  Future<Result<Task>> getTaskById(String id);

  /// Create a new task. Returns the created task with db-assigned timestamps.
  Future<Result<Task>> createTask(Task task);

  /// Update an existing task (non-recursive — subtasks are managed separately).
  Future<Result<Task>> updateTask(Task task);

  /// Delete a task and all its descendants (cascade).
  Future<Result<void>> deleteTask(String id);

  /// Toggle completion and propagate upward to parent percentage.
  Future<Result<Task>> toggleCompletion(String id);

  /// Update just the manual completion percentage (leaf-level slider).
  Future<Result<Task>> updateCompletionPercent(String id, double percent);

  /// Export all task data as JSON bytes for backup.
  Future<Result<List<int>>> exportBackup();

  /// Import and restore tasks from backup bytes.
  Future<Result<void>> importBackup(List<int> bytes);
}