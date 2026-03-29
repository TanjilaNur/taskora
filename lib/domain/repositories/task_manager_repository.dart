import '../entities/task.dart';
import '../../core/utils/result.dart';

/// The domain's contract for all task data operations.
/// Presentation and domain layers depend only on this interface —
/// the Isar implementation lives in the data layer.
abstract interface class TaskRepository {
  /// Fetch all root tasks (no parent) with their full subtree.
  Future<Result<List<Task>>> getRootTasks();

  /// Fetch a single task and its full subtree by id.
  Future<Result<Task>> getTaskById(String id);

  /// Create and persist a new task.
  Future<Result<Task>> createTask(Task task);

  /// Update an existing task (subtasks handled separately).
  Future<Result<Task>> updateTask(Task task);

  /// Delete a task and all its descendants.
  Future<Result<void>> deleteTask(String id);

  /// Toggle done/undone and propagate the change up to parent tasks.
  Future<Result<Task>> toggleCompletion(String id);

  /// Update the manual completion % on a leaf task (slider value).
  Future<Result<Task>> updateCompletionPercent(String id, double percent);

  /// Serialise all tasks to JSON bytes ready for export.
  Future<Result<List<int>>> exportBackup();

  /// Replace all tasks with the data from backup bytes.
  Future<Result<void>> importBackup(List<int> bytes);
}