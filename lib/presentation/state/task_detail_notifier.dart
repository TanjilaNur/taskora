import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/task/create_task_usecase.dart';
import '../providers/providers.dart';

/// ── States ────────────────────────────────────────────────────────────────────

sealed class TaskDetailState {
  const TaskDetailState();
}

/// Initial state while the task is being fetched.
final class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

/// Task loaded successfully — holds the full task with its subtree.
final class TaskDetailLoaded extends TaskDetailState {
  final Task task;
  const TaskDetailLoaded(this.task);
}

/// Something went wrong — holds the error message.
final class TaskDetailError extends TaskDetailState {
  final String message;
  const TaskDetailError(this.message);
}

/// ── Notifier ──────────────────────────────────────────────────────────────────

/// Drives the bottom-sheet detail view for a single task.
/// Each operation reloads the task after success to keep the UI fresh.
class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final Ref _ref;
  final String taskId;

  TaskDetailNotifier(this._ref, this.taskId)
      : super(const TaskDetailLoading()) {
    load();
  }

  Future<void> load() async {
    // Don't flash Loading if we already have data — stays on current state
    if (state is! TaskDetailLoaded) state = const TaskDetailLoading();
    final result = await _ref.read(taskRepositoryProvider).getTaskById(taskId);
    result.fold(
      ok: (t) => state = TaskDetailLoaded(t),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> addSubtask(
    String title,
    String? description, {
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? imagePath,
    String? imageUrl,
  }) async {
    final task = _currentTask;
    if (task == null || task.depth >= 4) return; // max depth guard

    final params = CreateTaskParams(
      title: title,
      description: description,
      parentId: task.id,
      depth: task.depth + 1,
      priority: priority,
      dueDate: dueDate,
      imagePath: imagePath,
      imageUrl: imageUrl,
    );
    final result = await _ref.read(createTaskUseCaseProvider).call(params);
    result.fold(
      ok:  (_) { load(); _reloadParent(task.parentId); },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> updateTask(Task updated) async {
    final parentId = _currentTask?.parentId;
    final result = await _ref.read(updateTaskUseCaseProvider).call(updated);
    result.fold(
      ok:  (_) { load(); _reloadParent(parentId); },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> toggleCompletion(String id) async {
    // Capture the viewing task's parentId (to refresh its parent if needed)
    final viewingParentId = _currentTask?.parentId;
    final result = await _ref.read(toggleCompletionUseCaseProvider).call(id);
    result.fold(
      ok:  (_) { load(); _reloadParent(viewingParentId); },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> updateCompletionPercent(String id, double percent) async {
    final parentId = _currentTask?.parentId;
    final result =
        await _ref.read(updateCompletionPercentUseCaseProvider).call(id, percent);
    result.fold(
      ok:  (_) { load(); _reloadParent(parentId); },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> deleteSubtask(String id) async {
    final parentId = _currentTask?.parentId;
    final result = await _ref.read(deleteTaskUseCaseProvider).call(id);
    result.fold(
      ok:  (_) { load(); _reloadParent(parentId); },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  /// Deletes this task without reloading — used when the sheet is already
  /// being dismissed so we don't trigger a rebuild on a gone widget.
  Future<void> deleteWithoutReload(String id) async {
    await _ref.read(deleteTaskUseCaseProvider).call(id);
  }

  /// Invalidates the parent task's provider so its completion %
  /// updates live — even if the user hasn't navigated back yet.
  void _reloadParent(String? parentId) {
    if (parentId == null) return;
    _ref.invalidate(taskDetailProvider(parentId));
  }

  Future<void> pickImage({bool fromCamera = false}) async {
    final task = _currentTask;
    if (task == null) return;
    final imageService = _ref.read(imageServiceProvider);
    final result = fromCamera
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();
    result.fold(
      ok: (path) async {
        if (task.imagePath != null) {
          await imageService.deleteImage(task.imagePath);
        }
        final updated = task.copyWith(imagePath: path, clearImageUrl: true);
        await updateTask(updated);
      },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> setImageFromUrl(String url) async {
    final task = _currentTask;
    if (task == null) return;
    final imageService = _ref.read(imageServiceProvider);
    final result = await imageService.downloadAndCacheUrl(url);
    result.fold(
      ok: (path) async {
        if (task.imagePath != null) {
          await imageService.deleteImage(task.imagePath);
        }
        final updated = task.copyWith(imagePath: path, imageUrl: url);
        await updateTask(updated);
      },
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> removeImage() async {
    final task = _currentTask;
    if (task == null) return;
    final imageService = _ref.read(imageServiceProvider);
    await imageService.deleteImage(task.imagePath);
    final updated = task.copyWith(clearImagePath: true, clearImageUrl: true);
    await updateTask(updated);
  }

  /// Returns the current task if loaded, null otherwise.
  Task? get _currentTask =>
      state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
}

final taskDetailProvider =
StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
      (ref, id) => TaskDetailNotifier(ref, id),
);