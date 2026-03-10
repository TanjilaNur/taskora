import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/todo/create_task_usecase.dart';
import '../providers/providers.dart';

sealed class TaskDetailState {
  const TaskDetailState();
}

final class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

final class TaskDetailLoaded extends TaskDetailState {
  final Task task;
  const TaskDetailLoaded(this.task);
}

final class TaskDetailError extends TaskDetailState {
  final String message;
  const TaskDetailError(this.message);
}

class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final Ref _ref;
  final String taskId;

  TaskDetailNotifier(this._ref, this.taskId)
      : super(const TaskDetailLoading()) {
    load();
  }

  Future<void> load() async {
    final result =
    await _ref.read(todoRepositoryProvider).getTaskById(taskId);
    result.fold(
      ok: (t) => state = TaskDetailLoaded(t),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> addSubtask(String title, String? description,
      {TaskPriority priority = TaskPriority.medium,
        DateTime? dueDate}) async {
    final task = _currentTask;
    if (task == null || task.depth >= 4) return;

    final params = CreateTaskParams(
      title: title,
      description: description,
      parentId: task.id,
      depth: task.depth + 1,
      priority: priority,
      dueDate: dueDate,
    );
    await _ref.read(createTaskUseCaseProvider).call(params);
    await load();
  }

  Future<void> updateTask(Task updated) async {
    await _ref.read(updateTaskUseCaseProvider).call(updated);
    await load();
  }

  Future<void> toggleCompletion(String id) async {
    await _ref.read(toggleCompletionUseCaseProvider).call(id);
    await load();
  }

  Future<void> updateCompletionPercent(String id, double percent) async {
    await _ref.read(updateCompletionPercentUseCaseProvider).call(id, percent);
    await load();
  }

  Future<void> deleteSubtask(String id) async {
    await _ref.read(deleteTaskUseCaseProvider).call(id);
    await load();
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
      err: (_) => null,
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
      err: (_) => null,
    );
  }

  Future<void> removeImage() async {
    final task = _currentTask;
    if (task == null) return;
    final imageService = _ref.read(imageServiceProvider);
    await imageService.deleteImage(task.imagePath);
    final updated =
    task.copyWith(clearImagePath: true, clearImageUrl: true);
    await updateTask(updated);
  }

  Task? get _currentTask =>
      state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
}

final taskDetailProvider =
StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
      (ref, id) => TaskDetailNotifier(ref, id),
);