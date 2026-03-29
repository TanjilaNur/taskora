import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_manager_repository.dart';
import '../../core/utils/result.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';
import '../models/task_model_mapper.dart';

class TaskManagerRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _dataSource;
  final Uuid _uuid;

  TaskManagerRepositoryImpl({
    required TaskLocalDataSource dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _uuid = uuid ?? const Uuid();


  // ─── Tree Assembly ────────────────────────────────────────────────────────

  /// Assembles a full tree from a flat list of models using parentId links.
  Future<List<TaskModel>> _buildTree(String? parentId) async {
    final models = await _dataSource.getModelsByParentId(parentId);
    for (final model in models) {
      model.subtasks = await _buildTree(model.id);
    }
    return models;
  }

  Future<TaskModel?> _buildSingleTree(String id) async {
    final model = await _dataSource.getModelById(id);
    if (model == null) return null;
    model.subtasks = await _buildTree(model.id);
    return model;
  }

  // ─── Repository Methods ───────────────────────────────────────────────────

  @override
  Future<Result<List<Task>>> getRootTasks() async {
    try {
      final roots = await _buildTree(null);
      return Ok(roots.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(Exception('Failed to load tasks: $e'));
    }
  }

  @override
  Future<Result<Task>> getTaskById(String id) async {
    try {
      final model = await _buildSingleTree(id);
      if (model == null) return Err(Exception('Task not found'));
      return Ok(model.toEntity());
    } catch (e) {
      return Err(Exception('Failed to get task: $e'));
    }
  }

  @override
  Future<Result<Task>> createTask(Task task) async {
    try {
      final model = task.copyWith(id: _uuid.v4()).toModel();
      await _dataSource.saveModel(model);
      return Ok(model.toEntity());
    } catch (e) {
      return Err(Exception('Failed to create task: $e'));
    }
  }

  @override
  Future<Result<Task>> updateTask(Task task) async {
    try {
      final model = task.toModel();
      await _dataSource.saveModel(model);
      final updated = await _buildSingleTree(task.id);
      return Ok(updated!.toEntity());
    } catch (e) {
      return Err(Exception('Failed to update task: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      await _dataSource.deleteWithChildren(id);
      return const Ok(null);
    } catch (e) {
      return Err(Exception('Failed to delete task: $e'));
    }
  }

  @override
  Future<Result<Task>> toggleCompletion(String id) async {
    try {
      final model = await _dataSource.getModelById(id);
      if (model == null) return Err(Exception('Task not found'));

      final now = DateTime.now();
      final newCompleted = !model.isCompleted;
      model
        ..isCompleted = newCompleted
        ..manualCompletionPercent = newCompleted ? 100.0 : 0.0
        ..completedAt = newCompleted ? now : null
        ..updatedAt = now;

      await _dataSource.saveModel(model);
      if (newCompleted) await _cascadeComplete(id, now);

      // Propagate upward: mark parents complete if all siblings done
      if (model.parentId != null) {
        await _propagateUpward(model.parentId!, now);
      }

      final updated = await _buildSingleTree(id);
      return Ok(updated!.toEntity());
    } catch (e) {
      return Err(Exception('Failed to toggle completion: $e'));
    }
  }

  Future<void> _cascadeComplete(String parentId, DateTime now) async {
    final children = await _dataSource.getModelsByParentId(parentId);
    for (final child in children) {
      child
        ..isCompleted = true
        ..manualCompletionPercent = 100.0
        ..completedAt = now
        ..updatedAt = now;
      await _dataSource.saveModel(child);
      await _cascadeComplete(child.id, now);
    }
  }

  /// Walk upward from [childParentId]: if ALL siblings of the changed task
  /// are now complete, mark the parent complete too, then recurse further up.
  Future<void> _propagateUpward(String parentId, DateTime now) async {
    final parent = await _dataSource.getModelById(parentId);
    if (parent == null) return;

    final siblings = await _dataSource.getModelsByParentId(parentId);
    final allDone = siblings.isNotEmpty && siblings.every((s) => s.isCompleted);

    if (allDone && !parent.isCompleted) {
      parent
        ..isCompleted = true
        ..manualCompletionPercent = 100.0
        ..completedAt = now
        ..updatedAt = now;
      await _dataSource.saveModel(parent);
      // Keep walking up the chain
      if (parent.parentId != null) {
        await _propagateUpward(parent.parentId!, now);
      }
    } else if (!allDone && parent.isCompleted) {
      // A sibling was un-completed — revert parent back to incomplete
      parent
        ..isCompleted = false
        ..manualCompletionPercent = 0.0
        ..completedAt = null
        ..updatedAt = now;
      await _dataSource.saveModel(parent);
      if (parent.parentId != null) {
        await _propagateUpward(parent.parentId!, now);
      }
    }
  }

  @override
  Future<Result<Task>> updateCompletionPercent(
      String id, double percent) async {
    try {
      final model = await _dataSource.getModelById(id);
      if (model == null) return Err(Exception('Task not found'));

      final now = DateTime.now();
      model
        ..manualCompletionPercent = percent
        ..isCompleted = percent >= 100.0
        ..completedAt = percent >= 100.0 ? now : null
        ..updatedAt = now;

      await _dataSource.saveModel(model);

      if (model.parentId != null) {
        await _propagateUpward(model.parentId!, now);
      }

      final updated = await _buildSingleTree(id);
      return Ok(updated!.toEntity());
    } catch (e) {
      return Err(Exception('Failed to update completion percent: $e'));
    }
  }

  @override
  Future<Result<List<int>>> exportBackup() async {
    try {
      final all = await _dataSource.getAllModels();
      final json = all
          .map((m) => {
        'id': m.id,
        'title': m.title,
        'description': m.description,
        'isCompleted': m.isCompleted,
        'manualCompletionPercent': m.manualCompletionPercent,
        'parentId': m.parentId,
        'imagePath': m.imagePath,
        'imageUrl': m.imageUrl,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
        'completedAt': m.completedAt?.toIso8601String(),
        'dueDate': m.dueDate?.toIso8601String(),
        'priority': m.priority,
        'depth': m.depth,
      })
          .toList();
      final bytes = utf8.encode(jsonEncode({'version': 2, 'tasks': json}));
      return Ok(bytes);
    } catch (e) {
      return Err(Exception('Export failed: $e'));
    }
  }

  @override
  Future<Result<void>> importBackup(List<int> bytes) async {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final tasks = (json['tasks'] as List).cast<Map<String, dynamic>>();

      final models = tasks
          .map((t) => TaskModel.create(
        id: t['id'] as String,
        title: t['title'] as String,
        description: t['description'] as String?,
        isCompleted: t['isCompleted'] as bool,
        manualCompletionPercent:
        (t['manualCompletionPercent'] as num).toDouble(),
        parentId: t['parentId'] as String?,
        imagePath: t['imagePath'] as String?,
        imageUrl: t['imageUrl'] as String?,
        createdAt: DateTime.parse(t['createdAt'] as String),
        updatedAt: DateTime.parse(t['updatedAt'] as String),
        completedAt: t['completedAt'] != null
            ? DateTime.parse(t['completedAt'] as String)
            : null,
        dueDate: t['dueDate'] != null
            ? DateTime.parse(t['dueDate'] as String)
            : null,
        priority: (t['priority'] as int?) ?? 1,
        depth: t['depth'] as int,
      ))
          .toList();

      await _dataSource.deleteAll();
      await _dataSource.saveModels(models);
      return const Ok(null);
    } catch (e) {
      return Err(Exception('Import failed: $e'));
    }
  }
}