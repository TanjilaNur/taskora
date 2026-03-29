import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/task/create_task_usecase.dart';
import '../providers/providers.dart';

// ── States ────────────────────────────────────────────────────────────────────

sealed class TaskListState { const TaskListState(); }

/// Shown while tasks are being fetched from the database.
final class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

/// Tasks loaded — also holds the active filter ('active' / 'completed' / null).
final class TaskListLoaded extends TaskListState {
  final List<Task> tasks;
  final String? filter; // null = show all

  const TaskListLoaded(this.tasks, {this.filter});

  /// Returns tasks sorted newest-first, filtered by [filter].
  List<Task> get filteredTasks {
    final sorted = [...tasks]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return switch (filter) {
      'active'    => sorted.where((t) => !t.isCompleted).toList(),
      'completed' => sorted.where((t) => t.isCompleted).toList(),
      _           => sorted,
    };
  }

  /// Returns a copy with optional overrides.
  /// Use [clearFilter] to reset the filter to null.
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

/// Something went wrong — [message] is shown in the UI.
final class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages the home screen task list.
/// Preserves the active filter across reloads so the tab never resets.
class TaskListNotifier extends StateNotifier<TaskListState> {
  final Ref _ref;

  TaskListNotifier(this._ref) : super(const TaskListLoading()) {
    load();
  }

  // Grab the current filter before going through Loading so we can restore it.
  String? get _currentFilter =>
      state is TaskListLoaded ? (state as TaskListLoaded).filter : null;

  Future<void> load() async {
    // Don't flash Loading if we already have data — update in place
    final previousFilter = _currentFilter;
    if (state is! TaskListLoaded) state = const TaskListLoading();
    final result = await _ref.read(getRootTasksUseCaseProvider).call();
    result.fold(
      ok:  (tasks) => state = TaskListLoaded(tasks, filter: previousFilter),
      err: (e)     => state = TaskListError(e.toString()),
    );
  }

  Future<void> createTask(CreateTaskParams params) async {
    final result = await _ref.read(createTaskUseCaseProvider).call(params);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  Future<void> updateTask(Task task) async {
    final result = await _ref.read(updateTaskUseCaseProvider).call(task);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  Future<void> deleteTask(String id) async {
    final result = await _ref.read(deleteTaskUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  Future<void> toggleCompletion(String id) async {
    final result = await _ref.read(toggleCompletionUseCaseProvider).call(id);
    result.fold(
      ok:  (_) => load(),
      err: (e) => state = TaskListError(e.toString()),
    );
  }

  /// Updates the filter chip selection. No-op when not in Loaded state.
  void setFilter(String? filter) {
    if (state is TaskListLoaded) {
      final s = state as TaskListLoaded;
      state = TaskListLoaded(s.tasks, filter: filter);
    }
  }

  /// Retry after an error — just triggers a fresh load.
  void retry() => load();
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>(
  (ref) => TaskListNotifier(ref),
);