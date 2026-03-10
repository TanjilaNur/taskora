import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/image_service.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_manager_repository_impl.dart';
import '../../domain/repositories/task_manager_repository.dart';
import '../../domain/usecases/backup/backup_usecases.dart';
import '../../domain/usecases/todo/create_task_usecase.dart';
import '../../domain/usecases/todo/delete_task_usecase.dart';
import '../../domain/usecases/todo/get_root_tasks_usecase.dart';
import '../../domain/usecases/todo/toggle_completion_usecase.dart';
import '../../domain/usecases/todo/update_completion_percent_usecase.dart';
import '../../domain/usecases/todo/update_task_usecase.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>(
      (ref) => TaskLocalDataSource(),
);

final imageServiceProvider = Provider<ImageService>(
      (ref) => ImageService(picker: ImagePicker(), uuid: const Uuid()),
);

// ─── Repository ───────────────────────────────────────────────────────────────

final todoRepositoryProvider = Provider<TodoRepository>(
      (ref) => TaskManagerRepositoryImpl(
    dataSource: ref.watch(taskLocalDataSourceProvider),
    uuid: const Uuid(),
  ),
);

// ─── Use Cases ────────────────────────────────────────────────────────────────

final getRootTasksUseCaseProvider = Provider(
      (ref) => GetRootTasksUseCase(ref.watch(todoRepositoryProvider)),
);

final createTaskUseCaseProvider = Provider(
      (ref) => CreateTaskUseCase(ref.watch(todoRepositoryProvider)),
);

final updateTaskUseCaseProvider = Provider(
      (ref) => UpdateTaskUseCase(ref.watch(todoRepositoryProvider)),
);

final deleteTaskUseCaseProvider = Provider(
      (ref) => DeleteTaskUseCase(ref.watch(todoRepositoryProvider)),
);

final toggleCompletionUseCaseProvider = Provider(
      (ref) => ToggleCompletionUseCase(ref.watch(todoRepositoryProvider)),
);

final updateCompletionPercentUseCaseProvider = Provider(
      (ref) => UpdateCompletionPercentUseCase(ref.watch(todoRepositoryProvider)),
);

final exportBackupUseCaseProvider = Provider(
      (ref) => ExportBackupUseCase(ref.watch(todoRepositoryProvider)),
);

final importBackupUseCaseProvider = Provider(
      (ref) => ImportBackupUseCase(ref.watch(todoRepositoryProvider)),
);