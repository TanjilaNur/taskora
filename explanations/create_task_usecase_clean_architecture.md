# 🏗️ CreateTaskUseCase — How It All Connects

## What is Clean Architecture?

Clean Architecture splits your app into **3 layers**, each with a strict rule:
> **Inner layers know nothing about outer layers.**

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │  ← UI, Widgets, State (Riverpod)
│   (home_page.dart, task_list_notifier)  │
├─────────────────────────────────────────┤
│           DOMAIN LAYER                  │  ← Business Rules (pure Dart)
│  (CreateTaskUseCase, TodoRepository,    │
│         Task entity)                    │
├─────────────────────────────────────────┤
│            DATA LAYER                   │  ← Database, APIs
│  (TaskManagerRepositoryImpl, Isar DB)   │
└─────────────────────────────────────────┘
```

---

## 📦 All the Files Involved

| File | Layer | Role |
|---|---|---|
| `home_page.dart` | Presentation | UI — shows the form, triggers creation |
| `task_form_sheet.dart` | Presentation | The bottom-sheet form widget |
| `task_list_notifier.dart` | Presentation | State manager (Riverpod Notifier) |
| `providers.dart` | Presentation | Wires all dependencies together |
| `create_task_usecase.dart` | **Domain** | ⭐ Business logic for creating a task |
| `task_manager_repository.dart` | Domain | Abstract contract (interface) |
| `task.dart` | Domain | The pure Task entity/model |
| `failures.dart` | Core | Error types (ValidationFailure, etc.) |
| `result.dart` | Core | Ok/Err wrapper — no exceptions thrown |
| `task_manager_repository_impl.dart` | Data | Real implementation using Isar DB |
| `task_local_datasource.dart` | Data | Raw Isar DB queries |

---

## 🔄 The Full Flow — Step by Step

```
USER taps "New Task" button
         │
         ▼
① home_page.dart  (_showCreateSheet)
   └─ Opens TaskFormSheet (bottom sheet)
   └─ User fills in: title, description, due date, priority

         │  User taps Submit
         ▼
② TaskFormSheet.onSubmit callback fires
   └─ Calls: ref.read(todoListProvider.notifier).createTask(
                CreateTaskParams(title, description, dueDate, priority)
             )

         │
         ▼
③ TaskListNotifier.createTask()  [task_list_notifier.dart]
   └─ Calls: _ref.read(createTaskUseCaseProvider).call(params)
   └─ This reads from providers.dart to get the UseCase instance

         │
         ▼
④ CreateTaskUseCase.call(params)  ⭐ [create_task_usecase.dart]
   └─ Validates title is not empty
   └─ Validates depth is not > 4
   └─ If invalid → returns Err(ValidationFailure(...))
   └─ If valid   → builds a Task entity with all fields
   └─ Calls: _repository.createTask(task)

         │
         ▼
⑤ TodoRepository.createTask()  [task_manager_repository.dart]
   └─ This is just an INTERFACE (abstract class)
   └─ The UseCase only knows about the interface, NOT the real DB

         │  (Dependency Injection via providers.dart)
         ▼
⑥ TaskManagerRepositoryImpl.createTask()  [task_manager_repository_impl.dart]
   └─ Generates a real UUID for the task id
   └─ Converts Task entity → TaskModel (DB format)
   └─ Calls: _dataSource.saveModel(model)

         │
         ▼
⑦ TaskLocalDataSource.saveModel()  [task_local_datasource.dart]
   └─ Writes to Isar (local database) using a transaction
   └─ db.writeTxn(() => db.taskModels.put(model))

         │
         ▼  Returns Result<Task> back up the chain
⑧ Back in TaskListNotifier
   └─ result.fold(ok: (_) => load(), err: (_) => load())
   └─ Calls load() to refresh the task list from DB

         │
         ▼
⑨ UI (home_page.dart) re-renders
   └─ ref.watch(todoListProvider) detects state change
   └─ New task appears in the list ✅
```

---

## 🧩 Breaking Down `create_task_usecase.dart` Line by Line

```dart
class CreateTaskParams {
  // This is just a "data bag" — carries inputs from UI to the use case
  final String title;
  final String? description;
  final String? parentId;   // If creating a subtask, parent's id goes here
  final int depth;          // 1 = root task, 2 = subtask, max 4
  final DateTime? dueDate;
  final TaskPriority priority;
}
```

```dart
class CreateTaskUseCase {
  final TodoRepository _repository;
  // ☝️ Depends on the INTERFACE, not the real DB class.
  // This is the "Dependency Inversion Principle" in Clean Architecture.

  Future<Result<Task>> call(CreateTaskParams params) async {
    // VALIDATION — business rules live here, not in the UI
    if (params.title.trim().isEmpty) {
      return Err(Exception(ValidationFailure('Title cannot be empty').message));
    }
    if (params.depth > 4) {
      return Err(Exception(ValidationFailure('Maximum nesting depth of 4 reached').message));
    }

    // BUILD the entity — id is empty string here, real UUID added by repo
    final task = Task(id: '', title: params.title.trim(), ...);

    // DELEGATE to the repository — UseCase doesn't care HOW it's saved
    return _repository.createTask(task);
  }
}
```

---

## 🔌 How Dependency Injection Works (providers.dart)

```dart
// Step 1: Create the DataSource (raw DB access)
final taskLocalDataSourceProvider = Provider((ref) => TaskLocalDataSource());

// Step 2: Create the Repository (wraps the DataSource)
final todoRepositoryProvider = Provider((ref) =>
  TaskManagerRepositoryImpl(dataSource: ref.watch(taskLocalDataSourceProvider))
);

// Step 3: Create the UseCase (wraps the Repository)
final createTaskUseCaseProvider = Provider((ref) =>
  CreateTaskUseCase(ref.watch(todoRepositoryProvider))
);
```
Riverpod builds this chain automatically. You never manually `new` these classes.

---

## 🛡️ Why `Result<Task>` Instead of Exceptions?

```dart
// Instead of try/catch everywhere in the UI...
final result = await createTaskUseCase.call(params);

result.fold(
  ok: (task) => print('Created: ${task.title}'),  // ✅ Success path
  err: (e)   => print('Failed: ${e.message}'),    // ❌ Error path
);
```
- `Ok<Task>` = success, contains the created Task
- `Err<Task>` = failure, contains the Exception
- No exceptions bubble up unexpectedly — every outcome is handled explicitly

---

## 🗝️ Key Principles Demonstrated

| Principle | How it's applied here |
|---|---|
| **Single Responsibility** | UseCase only validates + creates. UI only displays. DB only stores. |
| **Dependency Inversion** | UseCase depends on `TodoRepository` interface, not `TaskManagerRepositoryImpl` |
| **Separation of Concerns** | Business rules (depth ≤ 4) live in the domain, not in UI or DB |
| **Testability** | You can test `CreateTaskUseCase` with a fake repository, no real DB needed |

---

*Generated: March 11, 2026*
