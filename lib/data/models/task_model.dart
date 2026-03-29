import 'package:isar/isar.dart';

part 'task_model.g.dart';

/// Isar DB model for a task. Stored flat — one row per task.
/// [parentId] links subtasks to their parent; null = root task.
@Collection()
class TaskModel {
  Id get isarId => fastHash(id); // Isar requires an int ID — derived from uuid

  @Index(unique: true)
  late String id;

  late String title;
  String? description;
  late bool isCompleted;
  late double manualCompletionPercent;

  @Index() // indexed for fast parent→children queries
  String? parentId;

  String? imagePath;
  String? imageUrl;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? completedAt;
  DateTime? dueDate;
  late int priority; // 0=low, 1=medium, 2=high
  late int depth;    // 1=root … 4=max

  @ignore // assembled in memory by the repository, not stored
  List<TaskModel> subtasks = [];

  TaskModel();

  factory TaskModel.create({
    required String id,
    required String title,
    String? description,
    bool isCompleted = false,
    double manualCompletionPercent = 0.0,
    String? parentId,
    String? imagePath,
    String? imageUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    DateTime? dueDate,
    int priority = 1,
    int depth = 1,
  }) {
    return TaskModel()
      ..id = id
      ..title = title
      ..description = description
      ..isCompleted = isCompleted
      ..manualCompletionPercent = manualCompletionPercent
      ..parentId = parentId
      ..imagePath = imagePath
      ..imageUrl = imageUrl
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..completedAt = completedAt
      ..dueDate = dueDate
      ..priority = priority
      ..depth = depth;
  }
}

/// FNV-1a 64-bit hash — converts a string UUID into an Isar int ID.
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}