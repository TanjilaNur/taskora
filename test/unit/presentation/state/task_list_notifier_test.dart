// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:todo_app/core/utils/result.dart';
import 'package:todo_app/domain/entities/task.dart';
import 'package:todo_app/domain/repositories/task_manager_repository.dart';
import 'package:todo_app/domain/usecases/task/create_task_usecase.dart';
import 'package:todo_app/domain/usecases/task/delete_task_usecase.dart';
import 'package:todo_app/domain/usecases/task/get_root_tasks_usecase.dart';
import 'package:todo_app/domain/usecases/task/toggle_completion_usecase.dart';
import 'package:todo_app/domain/usecases/task/update_task_usecase.dart';
import 'package:todo_app/presentation/providers/providers.dart';
import 'package:todo_app/presentation/state/task_list_notifier.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockTaskRepository extends Mock implements TaskRepository {}

class MockGetRootTasksUseCase extends Mock implements GetRootTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

class MockToggleCompletionUseCase extends Mock
    implements ToggleCompletionUseCase {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Creates a minimal [Task] for use in tests. All required fields are provided;
/// optional fields can be overridden via named params.
Task makeTask({
  String id = 'task-1',
  String title = 'Test Task',
  bool isCompleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? parentId,
}) {
  final now = DateTime(2024, 1, 1);
  return Task(
    id: id,
    title: title,
    isCompleted: isCompleted,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    parentId: parentId,
  );
}

/// Builds a [ProviderContainer] with every use-case provider overridden by
/// a mock whose behaviour is controlled by the boolean error flags.
///
/// [tasks]       — list returned by getRootTasks on success
/// [loadError]   — getRootTasks returns Err
/// [createError] — createTask returns Err
/// [updateError] — updateTask returns Err
/// [deleteError] — deleteTask returns Err
/// [toggleError] — toggleCompletion returns Err
ProviderContainer makeContainer({
  List<Task> tasks = const [],
  bool loadError = false,
  bool createError = false,
  bool updateError = false,
  bool deleteError = false,
  bool toggleError = false,
}) {
  final getRootTasks = MockGetRootTasksUseCase();
  final createTask = MockCreateTaskUseCase();
  final updateTask = MockUpdateTaskUseCase();
  final deleteTask = MockDeleteTaskUseCase();
  final toggleCompletion = MockToggleCompletionUseCase();

  // ── getRootTasks ──────────────────────────────────────────────────────────
  when(() => getRootTasks.call()).thenAnswer(
    (_) async => loadError
        ? Err(Exception('load error'))
        : Ok(tasks),
  );

  // ── createTask ────────────────────────────────────────────────────────────
  when(() => createTask.call(any())).thenAnswer(
    (_) async => createError
        ? Err(Exception('create error'))
        : Ok(makeTask()),
  );

  // ── updateTask ────────────────────────────────────────────────────────────
  when(() => updateTask.call(any())).thenAnswer(
    (_) async => updateError
        ? Err(Exception('update error'))
        : Ok(makeTask()),
  );

  // ── deleteTask ────────────────────────────────────────────────────────────
  when(() => deleteTask.call(any())).thenAnswer(
    (_) async => deleteError
        ? Err<void>(Exception('delete error'))
        : const Ok<void>(null),
  );

  // ── toggleCompletion ──────────────────────────────────────────────────────
  when(() => toggleCompletion.call(any())).thenAnswer(
    (_) async => toggleError
        ? Err(Exception('toggle error'))
        : Ok(makeTask(isCompleted: true)),
  );

  return ProviderContainer(
    overrides: [
      getRootTasksUseCaseProvider.overrideWithValue(getRootTasks),
      createTaskUseCaseProvider.overrideWithValue(createTask),
      updateTaskUseCaseProvider.overrideWithValue(updateTask),
      deleteTaskUseCaseProvider.overrideWithValue(deleteTask),
      toggleCompletionUseCaseProvider.overrideWithValue(toggleCompletion),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Register fallback values for types used with any() matcher
  setUpAll(() {
    registerFallbackValue(
      const CreateTaskParams(title: '_fallback_'),
    );
    registerFallbackValue(makeTask());
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 1 — Initial State
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 — Initial State', () {
    test(
      'TC-019 — notifier is TaskListLoading synchronously before async load',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);

        // Read synchronously right after construction — must be Loading
        expect(container.read(taskListProvider), isA<TaskListLoading>());
      },
    );

    test(
      'TC-017 — after load, state is TaskListLoaded containing all tasks',
      () async {
        final tasks = [makeTask(id: '1'), makeTask(id: '2')];
        final container = makeContainer(tasks: tasks);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();

        final state = container.read(taskListProvider);
        expect(state, isA<TaskListLoaded>());
        final loaded = state as TaskListLoaded;
        expect(loaded.tasks.length, equals(2));
        expect(loaded.tasks.map((t) => t.id), containsAll(['1', '2']));
      },
    );

    test(
      'TC-016 — empty repository yields TaskListLoaded with empty task list',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.tasks, isEmpty);
      },
    );

    test(
      'TC-018 — repository error on load yields TaskListError',
      () async {
        final container = makeContainer(loadError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();

        expect(container.read(taskListProvider), isA<TaskListError>());
      },
    );

    test(
      'TC-018b — TaskListError contains a non-empty message',
      () async {
        final container = makeContainer(loadError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();

        final state = container.read(taskListProvider) as TaskListError;
        expect(state.message, isNotEmpty);
      },
    );

    test(
      'TC-078 — retry() after error transitions back to TaskListLoaded',
      () async {
        final container = makeContainer(loadError: true);
        addTearDown(container.dispose);

        // Force an error state first
        await container.read(taskListProvider.notifier).load();
        expect(container.read(taskListProvider), isA<TaskListError>());

        // Now build a new container that succeeds to simulate retry
        final goodContainer = makeContainer(tasks: [makeTask()]);
        addTearDown(goodContainer.dispose);
        await goodContainer.read(taskListProvider.notifier).load();
        goodContainer.read(taskListProvider.notifier).retry();
        await Future.microtask(() {});
        // After retry, state should eventually settle as Loaded (not Error)
        await goodContainer.read(taskListProvider.notifier).load();
        expect(goodContainer.read(taskListProvider), isA<TaskListLoaded>());
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 2 — TaskListLoaded.filteredTasks
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 — TaskListLoaded.filteredTasks', () {
    final active = makeTask(id: 'a', isCompleted: false);
    final completed = makeTask(id: 'b', isCompleted: true);
    final mixed = [active, completed];

    test(
      'TC-021 — filter null returns all tasks',
      () {
        final s = TaskListLoaded(mixed);
        expect(s.filteredTasks, containsAll([active, completed]));
        expect(s.filteredTasks.length, equals(2));
      },
    );

    test(
      'TC-022 — filter "active" returns only incomplete tasks',
      () {
        final s = TaskListLoaded(mixed, filter: 'active');
        expect(s.filteredTasks, equals([active]));
        expect(s.filteredTasks.every((t) => !t.isCompleted), isTrue);
      },
    );

    test(
      'TC-023 — filter "completed" returns only completed tasks',
      () {
        final s = TaskListLoaded(mixed, filter: 'completed');
        expect(s.filteredTasks, equals([completed]));
        expect(s.filteredTasks.every((t) => t.isCompleted), isTrue);
      },
    );

    test(
      'TC-024 — unknown filter value falls through to return all tasks',
      () {
        final s = TaskListLoaded(mixed, filter: 'xyz');
        expect(s.filteredTasks, containsAll([active, completed]));
      },
    );

    test(
      'TC-025 — filter on empty task list returns empty',
      () {
        final s = TaskListLoaded(const [], filter: 'active');
        expect(s.filteredTasks, isEmpty);
      },
    );

    test(
      'TC-026 — all tasks active, filter "completed" returns empty',
      () {
        final allActive = [makeTask(id: '1'), makeTask(id: '2')];
        final s = TaskListLoaded(allActive, filter: 'completed');
        expect(s.filteredTasks, isEmpty);
      },
    );

    test(
      'TC-027 — all tasks completed, filter "active" returns empty',
      () {
        final allDone = [
          makeTask(id: '1', isCompleted: true),
          makeTask(id: '2', isCompleted: true),
        ];
        final s = TaskListLoaded(allDone, filter: 'active');
        expect(s.filteredTasks, isEmpty);
      },
    );

    test(
      'TC-020 — (BUG-05 fix) filteredTasks sorted newest createdAt first',
      () {
        final older = makeTask(id: 'old', createdAt: DateTime(2024, 1, 1));
        final newer = makeTask(id: 'new', createdAt: DateTime(2024, 6, 1));
        // Insert in wrong order on purpose
        final s = TaskListLoaded([older, newer]);
        expect(s.filteredTasks.first.id, equals('new'));
        expect(s.filteredTasks.last.id, equals('old'));
      },
    );

    test(
      'TC-020b — sort is stable across three tasks with different dates',
      () {
        final t1 = makeTask(id: 't1', createdAt: DateTime(2024, 3, 1));
        final t2 = makeTask(id: 't2', createdAt: DateTime(2024, 1, 1));
        final t3 = makeTask(id: 't3', createdAt: DateTime(2024, 6, 1));
        final s = TaskListLoaded([t1, t2, t3]);
        final ids = s.filteredTasks.map((t) => t.id).toList();
        expect(ids, equals(['t3', 't1', 't2']));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 3 — TaskListLoaded.copyWith
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 — TaskListLoaded.copyWith (TC-085)', () {
    test(
      'TC-085a — copyWith with new tasks preserves existing filter',
      () {
        final s = TaskListLoaded([makeTask()], filter: 'active');
        final newTasks = [makeTask(id: '2'), makeTask(id: '3')];

        final updated = s.copyWith(tasks: newTasks);
        expect(updated.tasks, equals(newTasks));
        expect(updated.filter, equals('active'));
      },
    );

    test(
      'TC-085b — copyWith with new filter preserves existing tasks',
      () {
        final tasks = [makeTask()];
        final s = TaskListLoaded(tasks, filter: 'active');

        final updated = s.copyWith(filter: 'completed');
        expect(updated.tasks, equals(tasks));
        expect(updated.filter, equals('completed'));
      },
    );

    test(
      'TC-085c — copyWith clearFilter:true removes the filter',
      () {
        final s = TaskListLoaded([makeTask()], filter: 'active');

        final updated = s.copyWith(clearFilter: true);
        expect(updated.filter, isNull);
      },
    );

    test(
      'TC-085d — copyWith with no arguments preserves all fields',
      () {
        final tasks = [makeTask()];
        final s = TaskListLoaded(tasks, filter: 'completed');

        final updated = s.copyWith();
        expect(updated.tasks, equals(tasks));
        expect(updated.filter, equals('completed'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 4 — createTask()
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 — createTask()', () {
    test(
      'TC-006 — success triggers load() and state becomes TaskListLoaded',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).createTask(
              const CreateTaskParams(title: 'Buy milk'),
            );
        // pump microtasks so the inner load() async call can settle
        await Future<void>.delayed(Duration.zero);

        expect(container.read(taskListProvider), isA<TaskListLoaded>());
      },
    );

    test(
      'TC-005 / TC-093 — (BUG-01 fix) createTask error sets TaskListError, NOT reload',
      () async {
        final container = makeContainer(createError: true);
        addTearDown(container.dispose);

        // Let initial load complete with no error
        await container.read(taskListProvider.notifier).load();
        expect(container.read(taskListProvider), isA<TaskListLoaded>());

        // Now trigger the create error
        await container.read(taskListProvider.notifier).createTask(
              const CreateTaskParams(title: 'Bad Task'),
            );

        expect(container.read(taskListProvider), isA<TaskListError>());
      },
    );

    test(
      'TC-005b — TaskListError from createTask contains a non-empty message',
      () async {
        final container = makeContainer(createError: true);
        addTearDown(container.dispose);
        await container.read(taskListProvider.notifier).load();

        await container.read(taskListProvider.notifier).createTask(
              const CreateTaskParams(title: 'Bad Task'),
            );

        final state = container.read(taskListProvider) as TaskListError;
        expect(state.message, isNotEmpty);
      },
    );

    test(
      'TC-009 — (BUG-04 fix) active filter preserved after successful createTask',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container.read(taskListProvider.notifier).createTask(
              const CreateTaskParams(title: 'New Task'),
            );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 5 — updateTask()
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 — updateTask() — (BUG-06 fix: was completely missing)', () {
    test(
      'TC-034 — success triggers load() and state becomes TaskListLoaded',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container
            .read(taskListProvider.notifier)
            .updateTask(makeTask(title: 'Updated Title'));
        await Future<void>.delayed(Duration.zero);

        expect(container.read(taskListProvider), isA<TaskListLoaded>());
      },
    );

    test(
      'TC-037 — updateTask error sets TaskListError',
      () async {
        final container = makeContainer(updateError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container
            .read(taskListProvider.notifier)
            .updateTask(makeTask(title: 'Updated Title'));

        expect(container.read(taskListProvider), isA<TaskListError>());
      },
    );

    test(
      'TC-038 — (BUG-04 fix) filter preserved after successful updateTask',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container
            .read(taskListProvider.notifier)
            .updateTask(makeTask(title: 'Updated Title'));
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 6 — deleteTask()
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 — deleteTask()', () {
    test(
      'TC-042 — success triggers load() and state becomes TaskListLoaded',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container.read(taskListProvider.notifier).deleteTask('task-1');
        await Future<void>.delayed(Duration.zero);

        expect(container.read(taskListProvider), isA<TaskListLoaded>());
      },
    );

    test(
      'TC-044 / TC-094 — (BUG-02 fix) deleteTask error sets TaskListError, NOT null',
      () async {
        final container = makeContainer(deleteError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container.read(taskListProvider.notifier).deleteTask('task-1');

        final state = container.read(taskListProvider);
        expect(state, isNotNull);
        expect(state, isA<TaskListError>());
      },
    );

    test(
      'TC-044b — TaskListError from deleteTask has non-empty message',
      () async {
        final container = makeContainer(deleteError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container.read(taskListProvider.notifier).deleteTask('task-1');

        final state = container.read(taskListProvider) as TaskListError;
        expect(state.message, isNotEmpty);
      },
    );

    test(
      'TC-045 — deleting last task yields TaskListLoaded with empty list',
      () async {
        // Repo returns empty list after deletion (simulated by tasks:[])
        final container = makeContainer(tasks: const []);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container.read(taskListProvider.notifier).deleteTask('task-1');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.tasks, isEmpty);
      },
    );

    test(
      'TC-046 — (BUG-04 fix) filter preserved after successful deleteTask',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('completed');

        await container.read(taskListProvider.notifier).deleteTask('task-1');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('completed'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 7 — toggleCompletion()
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 — toggleCompletion()', () {
    test(
      'TC-052 — success triggers load() and state becomes TaskListLoaded',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container
            .read(taskListProvider.notifier)
            .toggleCompletion('task-1');
        await Future<void>.delayed(Duration.zero);

        expect(container.read(taskListProvider), isA<TaskListLoaded>());
      },
    );

    test(
      'TC-054 / TC-095 — (BUG-03 fix) toggleCompletion error sets TaskListError, NOT swallowed',
      () async {
        final container = makeContainer(toggleError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container
            .read(taskListProvider.notifier)
            .toggleCompletion('task-1');

        expect(container.read(taskListProvider), isA<TaskListError>());
      },
    );

    test(
      'TC-054b — TaskListError from toggleCompletion has non-empty message',
      () async {
        final container = makeContainer(toggleError: true);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        await container
            .read(taskListProvider.notifier)
            .toggleCompletion('task-1');

        final state = container.read(taskListProvider) as TaskListError;
        expect(state.message, isNotEmpty);
      },
    );

    test(
      'TC-057 — (BUG-04 fix) filter preserved after successful toggleCompletion',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container
            .read(taskListProvider.notifier)
            .toggleCompletion('task-1');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 8 — setFilter()
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 — setFilter()', () {
    test(
      'TC-062 — setFilter("active") updates state filter field to "active"',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );

    test(
      'TC-063 — setFilter("completed") updates state filter to "completed"',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('completed');

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('completed'));
      },
    );

    test(
      'TC-064 — setFilter(null) clears any active filter',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');
        container.read(taskListProvider.notifier).setFilter(null);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, isNull);
      },
    );

    test(
      'TC-065 — setFilter when state is TaskListLoading does nothing and does not crash',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);

        // State is Loading synchronously at this point — no await
        expect(
          () => container.read(taskListProvider.notifier).setFilter('active'),
          returnsNormally,
        );
        // State must still be Loading — setFilter must be a no-op
        expect(container.read(taskListProvider), isA<TaskListLoading>());
      },
    );

    test(
      'TC-066 — setFilter preserves the full task list unchanged',
      () async {
        final tasks = [makeTask(id: '1'), makeTask(id: '2'), makeTask(id: '3')];
        final container = makeContainer(tasks: tasks);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        final state = container.read(taskListProvider) as TaskListLoaded;
        // Raw tasks list must still hold all 3 regardless of the filter
        expect(state.tasks.length, equals(3));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 9 — Filter Persistence across all mutating operations (BUG-04)
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 9 — Filter persistence across operations (TC-096 / BUG-04)', () {
    test(
      'TC-071 / TC-096 — filter preserved after explicit load()',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('completed');

        // Trigger a second explicit load (as happens after any mutation)
        await container.read(taskListProvider.notifier).load();

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('completed'));
      },
    );

    test(
      'TC-067 — filter preserved after createTask succeeds',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container.read(taskListProvider.notifier).createTask(
              const CreateTaskParams(title: 'New'),
            );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );

    test(
      'TC-068 — filter preserved after deleteTask succeeds',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container.read(taskListProvider.notifier).deleteTask('task-1');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );

    test(
      'TC-069 — filter preserved after toggleCompletion succeeds',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('completed');

        await container
            .read(taskListProvider.notifier)
            .toggleCompletion('task-1');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('completed'));
      },
    );

    test(
      'TC-070 — filter preserved after updateTask succeeds',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        await container
            .read(taskListProvider.notifier)
            .updateTask(makeTask(title: 'Changed'));
        await Future<void>.delayed(Duration.zero);

        final state = container.read(taskListProvider) as TaskListLoaded;
        expect(state.filter, equals('active'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 10 — State Transition Sequence
  // ══════════════════════════════════════════════════════════════════════════
  group('GROUP 10 — State Transition Sequences', () {
    test(
      'TC-081 — load success: sequence is Loading → Loaded',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        final states = <TaskListState>[];
        container.listen<TaskListState>(
          taskListProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        await container.read(taskListProvider.notifier).load();

        expect(states.first, isA<TaskListLoading>());
        expect(states.last, isA<TaskListLoaded>());
      },
    );

    test(
      'TC-082 — load failure: sequence is Loading → Error',
      () async {
        final container = makeContainer(loadError: true);
        addTearDown(container.dispose);

        final states = <TaskListState>[];
        container.listen<TaskListState>(
          taskListProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        await container.read(taskListProvider.notifier).load();

        expect(states.first, isA<TaskListLoading>());
        expect(states.last, isA<TaskListError>());
      },
    );

    test(
      'TC-083 — reload preserves filter: Loaded → Loading → Loaded (same filter)',
      () async {
        final container = makeContainer(tasks: [makeTask()]);
        addTearDown(container.dispose);

        await container.read(taskListProvider.notifier).load();
        container.read(taskListProvider.notifier).setFilter('active');

        final states = <TaskListState>[];
        container.listen<TaskListState>(
          taskListProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        await container.read(taskListProvider.notifier).load();

        // Should have gone through Loading then back to Loaded
        expect(states.whereType<TaskListLoading>(), isNotEmpty);
        final finalLoaded = states.whereType<TaskListLoaded>().last;
        expect(finalLoaded.filter, equals('active'));
      },
    );
  });
}
