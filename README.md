# Taskora — Flutter Task Manager

> A Flutter application demonstrating **Clean Architecture**, **Riverpod** state management, **Isar** local persistence, hierarchical task management, and a comprehensive unit test suite.

---

## 📑 Table of Contents

1. [Overview](#-overview)
2. [Features](#-features)
3. [Architecture](#-architecture)
4. [Project Structure](#-project-structure)
5. [Data Layer](#-data-layer)
6. [State Management](#-state-management)
7. [Key Design Decisions](#-key-design-decisions)
8. [Navigation](#-navigation)
9. [Image Management](#-image-management)
10. [Backup & Restore](#-backup--restore)
11. [Testing](#-testing)
12. [Getting Started](#-getting-started)
13. [Dependencies](#-dependencies)
14. [Future Roadmap](#-future-roadmap)

---

## 🗺 Overview

**Taskora** is a comprehensive offline-first task management app. Users can create tasks, nest subtasks up to **4 levels deep**, attach thumbnail images, track hierarchical completion percentages, and back up their data — all without an internet connection.

The app was built against a formal product specification and satisfies every core requirement plus all bonus points:

| Requirement | Status |
|---|---|
| CRUD on tasks | ✅ |
| Delete with confirmation dialog | ✅ |
| Nested subtasks (3 levels below root = 4 total) | ✅ |
| Task thumbnail — gallery, camera, URL | ✅ |
| Image compressed to 250×250 px | ✅ |
| Bottom sheet modal with full CRUD | ✅ |
| Independent navigation stack inside modal | ✅ |
| Device back button handled inside modal | ✅ |
| Hierarchical completion % (leaf-based flat average) | ✅ |
| Completion date displayed on completed tasks | ✅ |
| Completing all subtasks auto-completes parent | ✅ |
| Isar local database with indexed queries | ✅ |
| Cascade delete on task hierarchies | ✅ |
| Offline-first | ✅ |
| **Bonus** — Clean Architecture | ✅ |
| **Bonus** — Backup export / import (JSON) | ✅ |
| **Bonus** — Dark / Light / System theme, persisted | ✅ |
| **Bonus** — Partial completion slider (leaf tasks) | ✅ |
| **Bonus** — Shimmer loading skeletons | ✅ |
| **Bonus** — Subtle animations (flutter_animate) | ✅ |
| **Bonus** — Filter: All / Active / Completed | ✅ |
| **Bonus** — Due dates & overdue indicators | ✅ |
| **Bonus** — Task priority (Low / Medium / High) | ✅ |

---

## ✨ Features

### Core CRUD
- **Create** tasks with title, optional description, image, due date, and priority
- **Read** all tasks on the home list with filter chips (All / Active / Done)
- **Update** any task's fields via the edit form — pre-fills all existing values
- **Delete** with a confirmation dialog — cascade-deletes all child subtasks

### Hierarchical Tasks
- Main tasks can have subtasks, which can have sub-subtasks — up to **4 levels total**
- The Add Subtask button is hidden at depth 4 to prevent further nesting
- Each level shows its own completion percentage and subtask count

### Completion System

Every task's completion percentage is calculated from the **leaves of its entire subtree** — not a simple average of direct children.

```
Root Task
  ├─ L2-A  (leaf, slider = 0%)
  └─ L2-B  (intermediate)
       ├─ L3-1  (leaf, 100% ✓)
       ├─ L3-2  (leaf, 100% ✓)
       ├─ L3-3  (leaf, 50% slider)
       └─ L3-4  (leaf, 0%)

Leaves = [L2-A=0, L3-1=100, L3-2=100, L3-3=50, L3-4=0]
Root %  = (0 + 100 + 100 + 50 + 0) / 5 = 50%
```

**Rule:** collect every leaf (task with no children) across all nesting levels and average their values equally. A branch with 4 leaves contributes 4× as much as a branch with 1 leaf — matching the spec requirement *"proportion of completed subtasks across all nesting levels"*.

**Leaf value:**
- `isCompleted = true` → `100%`
- `isCompleted = false` → `manualCompletionPercent` (0–100 via slider)

**Cascading rules:**
- Completing all leaves under a parent automatically marks that parent complete
- Un-completing any leaf reverts the parent back to incomplete
- Leaf tasks use a **slider** for partial completion (0–100%)
- Intermediate tasks show *"X of Y subtasks completed"* (leaf counts)
- Completed tasks display their exact completion date (`Completed Mar 29, 2026`)

### Images
- Pick from **gallery** or **camera**, or paste an **image URL**
- Images are automatically **compressed to 250×250 px / JPEG / 85% quality**
- Only the compressed version is stored — originals are discarded
- URL images are downloaded, compressed, and cached locally on save
- Fallback to a default placeholder when no image is set
- Images can be updated or removed at any time

### Backup & Restore
- **Export**: serialises all tasks to a JSON file, shared via the system share sheet
- **Import**: picks a `.taskora_backup` file, shows a confirmation warning, then **replaces** all existing tasks (not merges — see [design decision](#backup-replace-not-merge))

### Theme
- Light, Dark, and System modes available
- Selection is **persisted** via `SharedPreferences` and restored on next launch

---

## 🏗 Architecture

The project strictly follows **Clean Architecture** with three concentric layers:

```
┌─────────────────────────────────────────────┐
│               Presentation                  │  Flutter widgets, Riverpod notifiers
├─────────────────────────────────────────────┤
│                  Domain                     │  Pure Dart — entities, use cases, repo interface
├─────────────────────────────────────────────┤
│                   Data                      │  Isar models, ImageService, repo implementation
└─────────────────────────────────────────────┘
```

**Dependency rule**: arrows always point inward. The domain layer knows nothing about Flutter, Isar, or Riverpod.

### Layer Responsibilities

| Layer | Contains | Depends On |
|---|---|---|
| **Domain** | `Task` entity, `TaskRepository` interface, use cases | Nothing |
| **Data** | `TaskModel`, `TaskLocalDataSource`, `ImageService`, `TaskManagerRepositoryImpl` | Domain interfaces only |
| **Presentation** | Pages, widgets, `StateNotifier`s, Riverpod providers | Domain use cases only |
| **Core** | `Result<T>`, `AppFailure` types, `AppTheme`, `AppRouter`, constants | Nothing |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # thumbnailSize=250, maxDepth=4, backup extension
│   ├── errors/
│   │   └── failures.dart             # DatabaseFailure, ImageFailure, ValidationFailure, BackupFailure
│   ├── router/
│   │   └── app_router.dart           # GoRouter — single '/' route to HomePage
│   ├── theme/
│   │   ├── app_theme.dart            # Material 3 light + dark ThemeData
│   │   └── theme_provider.dart       # ThemeModeNotifier — persisted via SharedPreferences
│   └── utils/
│       └── result.dart               # sealed Result<T> { Ok<T> | Err<T> }
│
├── domain/
│   ├── entities/
│   │   └── task.dart                 # Pure Task entity + TaskPriority enum + copyWith
│   ├── repositories/
│   │   └── task_manager_repository.dart  # Abstract interface — 9 methods
│   └── usecases/
│       ├── task/
│       │   ├── create_task_usecase.dart      # Validates title, enforces depth ≤ 4
│       │   ├── update_task_usecase.dart      # Validates title, stamps updatedAt
│       │   ├── delete_task_usecase.dart      # Delegates to repo (cascade handled in data)
│       │   ├── get_root_tasks_usecase.dart   # Returns full task trees
│       │   ├── toggle_completion_usecase.dart
│       │   └── update_completion_percent_usecase.dart  # Clamps 0–100
│       └── backup/
│           └── backup_usecases.dart  # ExportBackupUseCase, ImportBackupUseCase
│
├── data/
│   ├── datasources/
│   │   ├── isar_service.dart         # Singleton Isar initialiser
│   │   ├── task_local_datasource.dart # Raw CRUD + cascade delete on flat TaskModel
│   │   └── image_service.dart        # Pick/compress/save/delete/download images
│   ├── models/
│   │   ├── task_model.dart           # @Collection Isar model with @Index on parentId
│   │   ├── task_model.g.dart         # Isar-generated schema (do not edit)
│   │   └── task_model_mapper.dart    # toEntity() / toModel() extension methods
│   └── repositories/
│       └── task_manager_repository_impl.dart  # Full implementation incl. tree assembly,
│                                              # cascade complete, propagateUpward
│
└── presentation/
    ├── pages/
    │   └── home/
    │       └── home_page.dart        # Task list, filter bar, FAB, backup menu
    ├── providers/
    │   └── providers.dart            # All Riverpod providers wired together
    ├── state/
    │   ├── task_list_notifier.dart   # TaskListState — Loading/Loaded/Error + filter
    │   └── task_detail_notifier.dart # TaskDetailState — for the bottom sheet
    └── widgets/
        ├── common/
        │   ├── empty_state.dart
        │   └── shimmer_list.dart
        └── task/
            ├── task_card.dart        # List item — thumbnail, progress, delete, swipe
            ├── task_detail_sheet.dart # Bottom sheet with nested Navigator
            ├── task_form_sheet.dart  # Create / Edit form with image picker
            └── subtask_tile.dart     # Subtask row with percent indicator
```

---

## 💾 Data Layer

### Entity vs Model separation

The `Task` domain entity is **pure Dart** — no Isar annotations, no JSON annotations:

```dart
class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final double manualCompletionPercent;  // used by leaf slider
  final String? parentId;
  final String? imagePath;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;           // stamped when toggled complete
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<Task> subtasks;             // assembled in memory, not stored flat
  final int depth;
}
```

The `TaskModel` is the Isar-annotated counterpart. It stores tasks **flat** in the database — one row per task, linked by `parentId`. The tree is assembled in memory by `_buildTree()` in the repository.

### Tree Assembly

```
DB (flat):
  id=1, parentId=null  ← root
  id=2, parentId=1     ← subtask
  id=3, parentId=2     ← sub-subtask

In memory after _buildTree(null):
  Task(id=1, subtasks=[
    Task(id=2, subtasks=[
      Task(id=3, subtasks=[])
    ])
  ])
```

### Cascade Delete

`TaskLocalDataSource.deleteWithChildren()` recursively collects all descendant IDs first, then deletes them all in a single write transaction — no orphaned records possible.

### Cascade Completion

When a task is toggled complete:
1. The task itself is marked complete + `completedAt` stamped
2. `_cascadeComplete()` marks all descendants complete recursively
3. `_propagateUpward()` walks up the `parentId` chain — if **all siblings** are now complete, the parent is auto-completed too. If a task is un-completed, the parent is reverted.

### Result Type

Every repository method returns `Result<T>` — a sealed class:

```dart
sealed class Result<T>
final class Ok<T>  extends Result<T> { final T data; }
final class Err<T> extends Result<T> { final Exception exception; }
```

Usage at the call site:
```dart
result.fold(
  ok:  (data) => // handle success,
  err: (e)    => // handle failure,
);
```

This makes error paths **impossible to ignore** — the compiler enforces both branches.

---

## ⚙️ State Management

### `TaskListState` (home screen)

```
TaskListLoading  — initial / during any reload
TaskListLoaded   — holds List<Task> + active filter string
TaskListError    — holds error message string
```

`TaskListLoaded.filteredTasks` is a computed getter:
- Sorts by `createdAt` descending (newest first)
- Filters by `'active'`, `'completed'`, or `null` (all)

**Filter persistence**: the current filter is captured before every `load()` call and restored afterward — switching tabs never resets the active filter.

**All mutating methods** (`createTask`, `updateTask`, `deleteTask`, `toggleCompletion`) follow the same pattern:
```dart
result.fold(
  ok:  (_) => load(),              // refresh list on success
  err: (e) => state = TaskListError(e.toString()),  // surface error on failure
);
```

### `TaskDetailState` (bottom sheet)

```
TaskDetailLoading  — while fetching the task by ID
TaskDetailLoaded   — holds the full Task with subtree
TaskDetailError    — holds error message
```

Every operation in `TaskDetailNotifier` (`addSubtask`, `updateTask`, `toggleCompletion`, `deleteSubtask`, `pickImage`, `setImageFromUrl`, `removeImage`) uses `result.fold` — no errors are silently swallowed.

---

## 🎨 Key Design Decisions

### `Result<T>` over exceptions
Exceptions thrown across layer boundaries create invisible contracts — callers don't know a method can fail unless they read the source. `Result<T>` makes failure a first-class citizen that the type system enforces at every call site.

### Flat storage, in-memory tree
Storing tasks flat (one row per task, linked by `parentId`) means:
- Simple indexed queries (`parentId == x`)
- No recursive DB transactions needed
- Easy cascade delete (collect IDs, delete in one `writeTxn`)
- The tree depth can change without schema migration

The trade-off is tree assembly on every read — acceptable for the task volumes this app targets.

### Image: compressed only, original discarded
The spec defines thumbnails as 250×250 visual identifiers, not archival photos. Storing originals alongside compressed copies would double storage consumption with zero user benefit. The compressed JPEG is all that is saved.

### Backup: replace, not merge
On import, `deleteAll()` runs before `saveModels()`. Merge semantics would require conflict resolution per UUID — if the same task ID exists in both the database and the backup file, the correct behaviour is ambiguous (keep newer? keep local? keep backup?). Replace semantics are unambiguous, safe, and clearly communicated to the user via the confirmation dialog: *"This will replace ALL current tasks."*

### Isar over Hive
| | Hive | Isar |
|---|---|---|
| Query builder | ❌ manual | ✅ full |
| Indexes | ❌ none | ✅ `@Index` |
| Performance | good | excellent (Rust core) |
| Schema migration | manual | built-in |
| Cascade operations | manual | native |

Isar is the successor recommended by the Hive author and the stronger choice for any app with relational data.

### Riverpod over Bloc
Bloc requires an Event class + State class + Bloc class per feature — three files minimum. Riverpod's `StateNotifier` is one class. Providers are also the DI container, eliminating the need for `GetIt` or similar. Type safety is equivalent; ceremony is far less.

---

## 🧭 Navigation

The app uses **two independent navigation stacks**:

```
GoRouter (main app stack)
  └── '/'  →  HomePage

Bottom Sheet (modal stack — separate Navigator)
  └── _TaskDetailPage(depth=1)      ← tapped task
        └── _TaskDetailPage(depth=2) ← tapped subtask
              └── _TaskDetailPage(depth=3) ← tapped sub-subtask
```

`PopScope` intercepts the Android hardware back button inside the modal:
- If the modal navigator has pages to pop → go back one level in the hierarchy
- If at the root level of the modal → close the bottom sheet entirely

This satisfies the spec requirement: *"Proper reaction of device navigation buttons."*

---

## 🖼 Image Management

```
User action
    │
    ├── Gallery / Camera
    │     ImagePicker → temp XFile
    │     FlutterImageCompress.compressAndGetFile()
    │         minWidth: 250, minHeight: 250
    │         quality: 85, format: JPEG
    │     Saved to: {appDocDir}/task_images/{uuid}.jpg
    │     task.imagePath = saved path
    │
    └── URL
          HEAD request to validate URL reachability
          On save: HttpClient.getUrl() → download bytes
          FlutterImageCompress.compressWithList()
          Saved to: {appDocDir}/task_images/{uuid}.jpg
          task.imagePath = saved path
          task.imageUrl  = original URL (for reference)
```

When a task image is **replaced or removed**, the old local file is deleted from disk by `ImageService.deleteImage()` before the new path is written — no orphaned files accumulate.

---

## 💾 Backup & Restore

### Export format
```json
{
  "version": 2,
  "tasks": [
    {
      "id": "uuid",
      "title": "Buy milk",
      "description": null,
      "isCompleted": false,
      "manualCompletionPercent": 0.0,
      "parentId": null,
      "imagePath": "/path/to/image.jpg",
      "imageUrl": null,
      "createdAt": "2026-03-29T10:00:00.000Z",
      "updatedAt": "2026-03-29T10:00:00.000Z",
      "completedAt": null,
      "dueDate": null,
      "priority": 1,
      "depth": 1
    }
  ]
}
```

The `version` field enables future schema migrations on import. The file is shared via the system share sheet as a `.taskora_backup` file.

### Restore flow
1. User taps **Import Backup** from the app menu
2. File picker opens — user selects a `.taskflow_backup` file
3. Confirmation dialog: *"This will replace ALL current tasks. Are you sure?"*
4. On confirm: `deleteAll()` → `saveModels(parsed tasks)` → list refreshed

---

## 🧪 Testing

### Strategy
The Clean Architecture layering makes each layer independently testable:

```
test/
└── unit/
    └── presentation/
        └── state/
            └── task_list_notifier_test.dart   ← 48 tests, 100% pass
```

### How it works

**Mocking**: Every use case is replaced with a `mocktail` mock via `ProviderContainer` overrides:
```dart
ProviderContainer(
  overrides: [
    getRootTasksUseCaseProvider.overrideWithValue(MockGetRootTasksUseCase()),
    createTaskUseCaseProvider.overrideWithValue(MockCreateTaskUseCase()),
    // ...
  ],
)
```

**No database, no Flutter**: Tests run in pure Dart — zero disk I/O, millisecond execution.

**`Result<T>` in mocks**: Mocks return your exact types:
```dart
when(() => mockCreate.call(any())).thenAnswer(
  (_) async => createError
      ? Err(Exception('create error'))   // Err constructor from result.dart
      : Ok(makeTask()),                   // Ok constructor from result.dart
);
```

### Test Groups & Coverage

| Group | Tests | What's Verified |
|---|---|---|
| Initial State | 6 | `TaskListLoading` on init, `TaskListLoaded` on success, `TaskListError` on failure |
| `filteredTasks` | 9 | All/active/completed filters, unknown filter, empty list, `createdAt` sort order |
| `copyWith` | 4 | Tasks preserved, filter preserved, `clearFilter`, no-arg |
| `createTask` | 4 | Success → reload, **BUG-01 regression** (error → `TaskListError` not reload), filter persistence |
| `updateTask` | 3 | Success, **BUG-06** (method was missing), filter persistence |
| `deleteTask` | 5 | Success, **BUG-02 regression** (error → `TaskListError` not null), empty list, filter persistence |
| `toggleCompletion` | 4 | Success, **BUG-03 regression** (error not swallowed), filter persistence |
| `setFilter` | 5 | Active/completed/null, no-op when loading, tasks list preserved |
| Filter persistence | 5 | **BUG-04 regression** — filter survives load/create/delete/toggle/update |
| State transitions | 3 | Loading→Loaded, Loading→Error, filter survives full reload cycle |
| **Total** | **48** | **100% pass** ✅ |

### Run the tests
```bash
flutter test test/unit/presentation/state/task_list_notifier_test.dart --reporter=expanded
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter `3.19+`
- Dart `3.0+`
- Xcode (for iOS/macOS builds)
- Android Studio / NDK (for Android builds)

### Setup
```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Isar schema + code-gen files
dart run build_runner build --delete-conflicting-outputs

# 3. Run on a connected device or emulator
flutter run
```

### iOS permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick task thumbnail images</string>
<key>NSCameraUsageDescription</key>
<string>Used to capture task thumbnail images</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Used to save task thumbnail images</string>
```

### Android permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

---

## 📦 Dependencies

### Production
| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management & dependency injection |
| `isar` + `xxf_isar_flutter_libs` | ^3.1.0 | Local database (Rust-powered, indexed) |
| `go_router` | ^13.2.0 | Declarative navigation |
| `image_picker` | ^1.1.2 | Gallery & camera image selection |
| `flutter_image_compress` | ^2.2.0 | 250×250 JPEG compression |
| `cached_network_image` | ^3.3.1 | URL image display with caching |
| `flutter_animate` | ^4.5.0 | Entrance & transition animations |
| `percent_indicator` | ^4.2.3 | Linear progress bars in subtask tiles |
| `shimmer` | ^3.0.0 | Loading skeleton screens |
| `share_plus` | ^9.0.0 | Backup file export via share sheet |
| `file_picker` | ^8.0.3 | Backup file import |
| `shared_preferences` | ^2.5.5 | Theme mode persistence |
| `path_provider` | ^2.1.3 | App documents directory for image storage |
| `uuid` | ^4.4.0 | Task ID generation |
| `intl` | ^0.19.0 | Date formatting |
| `gap` | ^3.0.1 | Spacing utility |

### Development
| Package | Version | Purpose |
|---|---|---|
| `mocktail` | ^1.0.4 | Mock generation for unit tests |
| `build_runner` | ^2.4.9 | Code generation runner |
| `isar_generator` | ^3.1.0 | Isar schema generation |
| `riverpod_generator` | ^2.4.0 | Riverpod provider generation |
| `freezed` | ^2.5.2 | Immutable model generation |
| `flutter_lints` | ^3.0.0 | Lint rules |

---

## 🔮 Future Roadmap

### Cloud Sync
The `TaskRepository` interface is the seam point. To add cloud sync:
1. Create `RemoteTaskRepositoryImpl` implementing `TaskRepository`
2. Create `SyncedTaskRepositoryImpl` composing local + remote
3. Swap the provider in `providers.dart` — **zero changes** to domain or presentation layers

### Potential Enhancements
- [ ] Task search / full-text filtering
- [ ] Push notifications for due date reminders
- [ ] Drag-and-drop task reordering
- [ ] Task tags / labels
- [ ] Recurring tasks
- [ ] iCloud / Google Drive backup destination
- [ ] Widget (home screen glanceable task count)

---

## 📄 Licence

This project was built as a take-home technical assessment. All rights reserved.
