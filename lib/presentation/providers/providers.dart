import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/image_service.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_manager_repository_impl.dart';
import '../../domain/repositories/task_manager_repository.dart';
import '../../domain/usecases/backup/backup_usecases.dart';
import '../../domain/usecases/task/create_task_usecase.dart';
import '../../domain/usecases/task/delete_task_usecase.dart';
import '../../domain/usecases/task/get_root_tasks_usecase.dart';
import '../../domain/usecases/task/toggle_completion_usecase.dart';
import '../../domain/usecases/task/update_completion_percent_usecase.dart';
import '../../domain/usecases/task/update_task_usecase.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>(
      (ref) => TaskLocalDataSource(),
);

final imageServiceProvider = Provider<ImageService>(
      (ref) => ImageService(picker: ImagePicker(), uuid: const Uuid()),
);

// ─── Repository ───────────────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>(
      (ref) => TaskManagerRepositoryImpl(
    dataSource: ref.watch(taskLocalDataSourceProvider),
    uuid: const Uuid(),
  ),
);

// ─── Use Cases ────────────────────────────────────────────────────────────────

final getRootTasksUseCaseProvider = Provider(
      (ref) => GetRootTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final createTaskUseCaseProvider = Provider(
      (ref) => CreateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final updateTaskUseCaseProvider = Provider(
      (ref) => UpdateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final deleteTaskUseCaseProvider = Provider(
      (ref) => DeleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final toggleCompletionUseCaseProvider = Provider(
      (ref) => ToggleCompletionUseCase(ref.watch(taskRepositoryProvider)),
);

final updateCompletionPercentUseCaseProvider = Provider(
      (ref) => UpdateCompletionPercentUseCase(ref.watch(taskRepositoryProvider)),
);

final exportBackupUseCaseProvider = Provider(
      (ref) => ExportBackupUseCase(ref.watch(taskRepositoryProvider)),
);

final importBackupUseCaseProvider = Provider(
      (ref) => ImportBackupUseCase(ref.watch(taskRepositoryProvider)),
);