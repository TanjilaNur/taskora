import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = task.completionPercentage / 100;
    final progressColor = _progressColor(pct, task.isOverdue, theme);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => false, // confirmation is handled by onDelete
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Thumbnail ──────────────────────────────────────────
              _Thumbnail(task: task),
              const Gap(12),

              // ── Right column ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + percentage on same line
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          '${task.completionPercentage.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                        const Gap(4),
                        // ── Delete button ──────────────────────────────
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    const Gap(3),

                    Row(
                      children: [
                        if (task.subtasks.isNotEmpty) ...[
                          Text(
                            '${task.subtasks.length} subtask${task.subtasks.length > 1 ? 's' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            _statusLabel(),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: task.isOverdue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: task.isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Gap(6),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: progressColor.withValues(alpha: 0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Spec: "Completed tasks will display the completion date"
  String _statusLabel() {
    if (task.isCompleted) {
      if (task.completedAt != null) {
        return 'Completed ${DateFormat('MMM d, yyyy').format(task.completedAt!)}';
      }
      return 'Completed';
    }
    if (task.isOverdue) {
      return 'Overdue · ${DateFormat('MMM d').format(task.dueDate!)}';
    }
    if (task.dueDate != null) {
      return 'Due ${DateFormat('MMM d').format(task.dueDate!)}';
    }
    return _timeAgo(task.createdAt);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Color _progressColor(double pct, bool overdue, ThemeData theme) {
    if (overdue) return theme.colorScheme.error;
    if (pct >= 1.0) return const Color(0xFF4CAF50);
    if (pct >= 0.5) return Colors.orange;
    return const Color(0xFF3D6FFF);
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final Task task;
  const _Thumbnail({required this.task});

  @override
  Widget build(BuildContext context) {
    const size = 58.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imageWidget(size),
            if (task.isCompleted)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageWidget(double size) {
    if (task.imagePath != null) {
      return Image.file(File(task.imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultImage(size));
    }
    if (task.imageUrl != null) {
      return CachedNetworkImage(
          imageUrl: task.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _defaultImage(size));
    }
    return _defaultImage(size);
  }

  Widget _defaultImage(double size) {
    return Image.asset(
      'assets/images/default_task.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
