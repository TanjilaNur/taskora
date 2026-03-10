import '../../domain/entities/task.dart';
import 'task_model.dart';

extension TaskModelMapper on TaskModel {
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      manualCompletionPercent: manualCompletionPercent,
      parentId: parentId,
      imagePath: imagePath,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      dueDate: dueDate,
      priority: TaskPriorityExtension.fromInt(priority),
      depth: depth,
      subtasks: subtasks.map((s) => s.toEntity()).toList(),
    );
  }
}

extension TodoTaskMapper on Task {
  TaskModel toModel() {
    return TaskModel.create(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      manualCompletionPercent: manualCompletionPercent,
      parentId: parentId,
      imagePath: imagePath,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      dueDate: dueDate,
      priority: priority.sortValue,
      depth: depth,
    );
  }
}