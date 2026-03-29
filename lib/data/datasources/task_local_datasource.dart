import 'package:isar/isar.dart';

import '../models/task_model.dart';
import 'isar_service.dart';

/// Direct Isar access layer. Works only with [TaskModel] — no domain types.
class TaskLocalDataSource {
  Isar get _db => IsarService.instance;

  /// Returns all rows flat (no tree structure).
  Future<List<TaskModel>> getAllModels() async {
    return _db.taskModels.where().findAll();
  }

  /// Returns direct children of [parentId]. Pass null to get root tasks.
  Future<List<TaskModel>> getModelsByParentId(String? parentId) async {
    if (parentId == null) {
      return _db.taskModels
          .filter()
          .parentIdIsNull()
          .sortByCreatedAt()
          .findAll();
    }
    return _db.taskModels
        .filter()
        .parentIdEqualTo(parentId)
        .sortByCreatedAt()
        .findAll();
  }

  Future<TaskModel?> getModelById(String id) async {
    return _db.taskModels.filter().idEqualTo(id).findFirst();
  }

  Future<void> saveModel(TaskModel model) async {
    await _db.writeTxn(() => _db.taskModels.put(model));
  }

  Future<void> saveModels(List<TaskModel> models) async {
    await _db.writeTxn(() => _db.taskModels.putAll(models));
  }

  /// Collects all descendant IDs then deletes them in a single bulk operation.
  Future<void> deleteWithChildren(String id) async {
    final allModels = await getAllModels();
    final toDelete  = _collectIds(id, allModels).toList();
    await _db.writeTxn(() =>
      _db.taskModels.filter().anyOf(toDelete, (q, tid) => q.idEqualTo(tid)).deleteAll()
    );
  }

  /// Wipes the entire tasks table (used before a backup restore).
  Future<void> deleteAll() async {
    await _db.writeTxn(() => _db.taskModels.clear());
  }

  // Recursively collects [rootId] and all its descendants.
  Set<String> _collectIds(String rootId, List<TaskModel> all) {
    final ids = <String>{rootId};
    final children = all.where((m) => m.parentId == rootId);
    for (final child in children) {
      ids.addAll(_collectIds(child.id, all));
    }
    return ids;
  }
}