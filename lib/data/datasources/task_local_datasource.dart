import 'package:isar/isar.dart';

import '../models/task_model.dart';
import 'isar_service.dart';

/// Raw data source — speaks only in [TaskModel], knows nothing about domain.
class TaskLocalDataSource {
  Isar get _db => IsarService.instance;

  /// Returns all flat models (no hierarchy assembled here).
  Future<List<TaskModel>> getAllModels() async {
    return _db.taskModels.where().findAll();
  }

  /// Returns flat models for a given parentId (null = root).
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

  /// Cascade delete: deletes the task and all descendants recursively.
  Future<void> deleteWithChildren(String id) async {
    final allModels = await getAllModels();
    final toDelete = _collectIds(id, allModels);
    await _db.writeTxn(() async {
      for (final tid in toDelete) {
        await _db.taskModels.filter().idEqualTo(tid).deleteFirst();
      }
    });
  }

  Future<void> deleteAll() async {
    await _db.writeTxn(() => _db.taskModels.clear());
  }

  Set<String> _collectIds(String rootId, List<TaskModel> all) {
    final ids = <String>{rootId};
    final children = all.where((m) => m.parentId == rootId);
    for (final child in children) {
      ids.addAll(_collectIds(child.id, all));
    }
    return ids;
  }
}