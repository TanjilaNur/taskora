/// Priority level of a task. Stored as int (0/1/2) in the database.
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

/// Core task entity. Pure Dart — no Flutter, Isar, or JSON dependencies.
///
/// Tasks are stored flat in the DB (linked by [parentId]).
/// The [subtasks] list is assembled in memory by the repository.
class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;

  /// Used by the leaf-task slider (0–100). Ignored when subtasks exist.
  final double manualCompletionPercent;

  /// null = root task. Set to parent's id for subtasks.
  final String? parentId;

  final String? imagePath; // local file path after compression
  final String? imageUrl;  // original URL (kept for reference)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt; // stamped when task is marked done
  final DateTime? dueDate;
  final TaskPriority priority;

  /// Children assembled in memory — not a DB column.
  final List<Task> subtasks;

  /// 1 = root, 4 = deepest allowed level.
  final int depth;

  Task({
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

  /// Completion % calculated from ALL leaves across the entire subtree.
  ///
  /// Spec: "percentage reflects the proportion of completed subtasks
  /// across all nesting levels."
  ///
  /// Every leaf (task with no children) contributes equally — regardless
  /// of which branch it lives in. A branch with 4 leaves is 4× more
  /// influential than a branch with 1 leaf.
  ///
  /// Leaf value:
  ///   - completed           → 100%
  ///   - not completed       → manualCompletionPercent (0–100 via slider)
  /// Lazily cached leaf values — computed once, reused by all three getters.
  List<double>? _cachedLeaves;
  List<double> get _leaves => _cachedLeaves ??= _collectLeaves();

  double get completionPercentage {
    final leaves = _leaves;
    if (leaves.isEmpty) {
      return isCompleted ? 100.0 : manualCompletionPercent;
    }
    return leaves.fold(0.0, (sum, v) => sum + v) / leaves.length;
  }

  /// Recursively collects the completion value of every leaf in the subtree.
  List<double> _collectLeaves() {
    if (subtasks.isEmpty) return [];
    final result = <double>[];
    for (final sub in subtasks) {
      if (sub.subtasks.isEmpty) {
        result.add(sub.isCompleted ? 100.0 : sub.manualCompletionPercent);
      } else {
        result.addAll(sub._collectLeaves());
      }
    }
    return result;
  }

  bool get isFullyComplete => completionPercentage >= 100.0;

  /// True if past due date and not yet completed.
  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  /// Number of leaf tasks fully complete.
  int get completedSubtaskCount => _leaves.where((v) => v >= 100.0).length;

  /// Total leaf task count.
  int get totalSubtaskCount => _leaves.length;

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