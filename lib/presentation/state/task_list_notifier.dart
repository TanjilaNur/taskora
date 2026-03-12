import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/task/create_task_usecase.dart';
import '../providers/providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

sealed class TaskListState {
  const TaskListState();
}

final class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

final class TaskListLoaded extends TaskListState {
  final List<Task> tasks;
  final String? filter; // null = all, 'active', 'completed'
  const TaskListLoaded(this.tasks, {this.filter});

  List<Task> get filteredTasks => switch (filter) {
    'active' => tasks.where((t) => !t.isCompleted).toList(),
    'completed' => tasks.where((t) => t.isCompleted).toList(),
    _ => tasks,
  };
}

final class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TaskListNotifier extends StateNotifier<TaskListState> {
  final Ref _ref;

  TaskListNotifier(this._ref) : super(const TaskListLoading()) {
    load();
  }

  Future<void> load() async {
    state = const TaskListLoading();
    final result = await _ref.read(getRootTasksUseCaseProvider).call();
    result.fold(
      ok: (tasks) => state = TaskListLoaded(tasks),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  Future<void> createTask(CreateTaskParams params) async {
    final result = await _ref.read(createTaskUseCaseProvider).call(params);
    result.fold(ok: (_) => load(), err: (_) => load());
  }

  Future<void> deleteTask(String id) async {
    final result = await _ref.read(deleteTaskUseCaseProvider).call(id);
    result.fold(ok: (_) => load(), err: (_) => null);
  }

  Future<void> toggleCompletion(String id) async {
    await _ref.read(toggleCompletionUseCaseProvider).call(id);
    load();
  }

  void setFilter(String? filter) {
    if (state is TaskListLoaded) {
      final s = state as TaskListLoaded;
      state = TaskListLoaded(s.tasks, filter: filter);
    }
  }
}

final taskListProvider =
StateNotifierProvider<TaskListNotifier, TaskListState>(
      (ref) => TaskListNotifier(ref),
);