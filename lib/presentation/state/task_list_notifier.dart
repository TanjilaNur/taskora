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

  // BUG-05 FIX: sort by createdAt descending so newest tasks appear first
  List<Task> get filteredTasks {
    final sorted = [...tasks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return switch (filter) {
      'active'    => sorted.where((t) => !t.isCompleted).toList(),
      'completed' => sorted.where((t) => t.isCompleted).toList(),
      _           => sorted,
    };
  }

  // BUG-04 FIX: copyWith so filter can be carried through reloads
  TaskListLoaded copyWith({
    List<Task>? tasks,
    String? filter,
    bool clearFilter = false,
  }) {
    return TaskListLoaded(
      tasks ?? this.tasks,
      filter: clearFilter ? null : (filter ?? this.filter),
    );
  }
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

  // Capture the current filter before any reload so it can be restored
  String? get _currentFilter =>
      state is TaskListLoaded ? (state as TaskListLoaded).filter : null;

  Future<void> load() async {
    final previousFilter = _currentFilter; // BUG-04 FIX: preserve filter
    state = const TaskListLoading();
    final result = await _ref.read(getRootTasksUseCaseProvider).call();
    result.fold(
      ok: (tasks) => state = TaskListLoaded(tasks, filter: previousFilter),
      err: (e)    => state = TaskListError(e.toString()),
    );
  }

  // BUG-01 FIX: error path now sets TaskListError instead of calling load()
  Future<void> createTask(CreateTaskParams params) async {
    final result = await _ref.read(createTaskUseCaseProvider).call(params);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  // BUG-06 FIX: updateTask was completely missing — added with proper error handling
  Future<void> updateTask(Task task) async {
    final result = await _ref.read(updateTaskUseCaseProvider).call(task);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  // BUG-02 FIX: error path now sets TaskListError instead of null
  Future<void> deleteTask(String id) async {
    final result = await _ref.read(deleteTaskUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  // BUG-03 FIX: result is now checked; error sets TaskListError instead of being swallowed
  Future<void> toggleCompletion(String id) async {
    final result = await _ref.read(toggleCompletionUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  void setFilter(String? filter) {
    if (state is TaskListLoaded) {
      final s = state as TaskListLoaded;
      state = TaskListLoaded(s.tasks, filter: filter);
    }
  }

  // BUG-07 FIX: retry() method for error recovery triggered from the UI
  void retry() => load();
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>(
  (ref) => TaskListNotifier(ref),
);