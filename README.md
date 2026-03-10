# TaskFlow — Flutter Todo App

A senior-level take-home project demonstrating Clean Architecture, Riverpod state management, Isar persistence, and a modular, testable codebase.

---

## 🏗️ Architecture

This project follows **Clean Architecture** — each layer has a single responsibility and depends only inward.

```
lib/
├── core/                         # Shared utilities, constants, DI-agnostic
│   ├── constants/
│   ├── errors/                   # Failure types
│   ├── router/                   # go_router setup
│   ├── theme/                    # Material3 themes + ThemeMode provider
│   └── utils/                    # Result<T> type
│
├── domain/                       # Pure Dart — no Flutter, no packages
│   ├── entities/                 # TodoTask entity
│   ├── repositories/             # Abstract interface (TodoRepository)
│   └── usecases/                 # One class per use case
│
├── data/                         # Repository implementation + data sources
│   ├── datasources/              # IsarService, TaskLocalDataSource, ImageService
│   ├── models/                   # Isar-annotated TaskModel + mapper
│   └── repositories/             # TodoRepositoryImpl
│
└── presentation/                 # Flutter UI
    ├── pages/                    # Route-level pages
    ├── providers/                # Riverpod DI providers
    ├── state/                    # StateNotifiers (business logic for UI)
    └── widgets/                  # Reusable, composable widgets
```

---

## 📐 Key Architectural Decisions

### Why Clean Architecture?
- **Testability**: Domain layer has zero framework dependencies. Use cases and entities are plain Dart — testable without mocking Flutter.
- **Scalability**: Swapping Isar for a remote API only touches the `data` layer.
- **Separation of concerns**: Each layer communicates through abstractions (interfaces), not concrete implementations.

### Why Riverpod (not Bloc)?
- **Type-safe**: `Provider.family`, `StateNotifierProvider` catch mistakes at compile time.
- **No boilerplate**: Bloc requires Events + States + Bloc class per feature. Riverpod's `StateNotifier` is leaner.
- **DI built-in**: Riverpod replaces service locators like GetIt. Providers *are* the dependency injection container.
- **Code generation ready**: `riverpod_generator` + `riverpod_annotation` for zero-boilerplate providers in future iterations.

### Why Isar (not Hive)?
| | Hive | Isar |
|---|---|---|
| Querying | Manual, limited | Full query builder with indexes |
| Relations | None native | Native via IsarLinks |
| Performance | Good | Excellent (written in Rust) |
| Schema migration | Manual | Built-in |
| Cascade delete | Manual | Native |

Isar is the successor recommended by the Hive author. For a task hierarchy with indexed parentId queries and future migration support, Isar is the stronger choice.

### Why `Result<T>` instead of exceptions?
Exceptions that cross layer boundaries create invisible contracts. A `Result<T>` sealed class makes error handling explicit and type-safe at every call site — the compiler forces you to handle both `Ok` and `Err`.

---

## ✅ Features Implemented

| Feature | Status |
|---|---|
| CRUD on tasks | ✅ |
| 3-level nested subtasks (4 levels total) | ✅ |
| Task thumbnail (gallery, camera, URL) | ✅ |
| Image compression to 250×250 | ✅ |
| Image caching locally | ✅ |
| Bottom sheet modal | ✅ |
| Nested Navigator inside modal | ✅ |
| Back navigation within modal | ✅ |
| Recursive completion % calculation | ✅ |
| Completion date display | ✅ |
| Cascade completion of subtasks | ✅ |
| Slider for partial completion (leaf tasks) | ✅ (Bonus) |
| Isar local database | ✅ |
| Offline-first | ✅ |
| Export / Import backup (JSON) | ✅ (Bonus) |
| Dark/Light theme toggle | ✅ (Bonus) |
| Shimmer loading | ✅ (Bonus) |
| Filter: All / Active / Completed | ✅ |
| Delete confirmation dialog | ✅ |
| Smooth animations (flutter_animate) | ✅ (Bonus) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.19+
- Dart 3.0+

### Setup

```bash
# Clone and install
flutter pub get

# Generate Isar schema + Riverpod code
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run
```

### iOS-specific
Ensure your `Info.plist` includes:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick task thumbnail images</string>
<key>NSCameraUsageDescription</key>
<string>Used to capture task thumbnail images</string>
```

### Android-specific
In `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

---

## 🧪 Testing Strategy

The Clean Architecture structure makes testing straightforward:

```
test/
├── domain/
│   ├── usecases/           # Unit test each use case with mock repository
│   └── entities/           # Test completionPercentage calculation
├── data/
│   └── repositories/       # Integration test with in-memory Isar instance
└── presentation/
    └── state/              # Widget test StateNotifiers with ProviderContainer
```

Example use case test (no Flutter needed):
```dart
test('createTask fails when title is empty', () async {
  final useCase = CreateTaskUseCase(MockTodoRepository());
  final result = await useCase(CreateTaskParams(title: ''));
  expect(result.isErr, true);
});
```

---

## 🔮 Future Cloud Sync

The `TodoRepository` interface is the seam. To add cloud sync:

1. Create `CloudTodoRepositoryImpl` implementing `TodoRepository`.
2. Create `SyncedTodoRepositoryImpl` wrapping both local and cloud.
3. Swap the provider — zero changes to domain or presentation layers.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management & DI |
| `isar` + `isar_flutter_libs` | Local database |
| `go_router` | Navigation |
| `image_picker` | Gallery/camera access |
| `flutter_image_compress` | Thumbnail compression |
| `cached_network_image` | URL image caching |
| `flutter_animate` | Animations |
| `percent_indicator` | Progress bars |
| `shimmer` | Loading skeletons |
| `share_plus` | Backup export |
| `file_picker` | Backup import |
| `freezed` | Immutable models (ready for expansion) |
| `uuid` | Unique task IDs |
| `gap` | Spacing utility |
