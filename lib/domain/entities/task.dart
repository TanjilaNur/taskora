enum TaskPriority {
  low,
  medium,
  high
}

extension TaskPriorityExtension on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  int get sortValue => switch (this) {
    TaskPriority.low => 0,
    TaskPriority.medium => 1,
    TaskPriority.high => 2,
  };

  static TaskPriority fromInt(int value) => switch (value) {
    0 => TaskPriority.low,
    2 => TaskPriority.high,
    _ => TaskPriority.medium,
  };
}

/// Pure domain entity — no Flutter, no Isar, no JSON annotations.
class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final double manualCompletionPercent;
  final String? parentId;
  final String? imagePath;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<Task> subtasks;
  final int depth;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.manualCompletionPercent = 0.0,
    this.parentId,
    this.imagePath,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.subtasks = const [],
    this.depth = 1,
  });

  double get completionPercentage {
    if (subtasks.isEmpty) {
      return isCompleted ? 100.0 : manualCompletionPercent;
    }
    double total = 0;
    for (final sub in subtasks) {
      total += sub.completionPercentage;
    }
    return total / subtasks.length;
  }

  bool get isFullyComplete => completionPercentage >= 100.0;
  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  int get completedSubtaskCount =>
      subtasks.where((s) => s.isFullyComplete).length +
          subtasks.fold(0, (sum, s) => sum + s.completedSubtaskCount);

  int get totalSubtaskCount =>
      subtasks.length +
          subtasks.fold(0, (sum, s) => sum + s.totalSubtaskCount);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    double? manualCompletionPercent,
    String? parentId,
    String? imagePath,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? dueDate,
    TaskPriority? priority,
    List<Task>? subtasks,
    int? depth,
    bool clearParentId = false,
    bool clearImagePath = false,
    bool clearImageUrl = false,
    bool clearCompletedAt = false,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      manualCompletionPercent:
      manualCompletionPercent ?? this.manualCompletionPercent,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      depth: depth ?? this.depth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && id == other.id;

  @override
  int get hashCode => id.hashCode;
}