import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/task/create_task_usecase.dart';
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
    await _ref.read(taskRepositoryProvider).getTaskById(taskId);
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
    if (task == null || task.depth >= 4) return;

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
      ok:  (_) => load(),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> updateTask(Task updated) async {
    final result = await _ref.read(updateTaskUseCaseProvider).call(updated);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> toggleCompletion(String id) async {
    final result = await _ref.read(toggleCompletionUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> updateCompletionPercent(String id, double percent) async {
    final result =
        await _ref.read(updateCompletionPercentUseCaseProvider).call(id, percent);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskDetailError(e.toString()),
    );
  }

  Future<void> deleteSubtask(String id) async {
    final result = await _ref.read(deleteTaskUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskDetailError(e.toString()),
    );
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

  Task? get _currentTask =>
      state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
}

final taskDetailProvider =
StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
      (ref, id) => TaskDetailNotifier(ref, id),
);