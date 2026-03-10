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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Thumbnail ────────────────────────────────────────
            _Thumbnail(task: task),
            const Gap(12),

            // ── Right column ─────────────────────────────────────
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
                    ],
                  ),

                  const Gap(3),

                  Row(
                    children: [
                      if (task.subtasks.isNotEmpty) ...
                      [
                        Text(
                          '${task.subtasks.length} subtask${task.subtasks.length > 1 ? 's' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color:
                              theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          _statusLabel(),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: task.isOverdue
                                ? theme.colorScheme.error
                                : task.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: task.isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // // Status label
                  // Text(
                  //   _statusLabel(),
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: task.isOverdue
                  //         ? theme.colorScheme.error
                  //         : theme.colorScheme.onSurfaceVariant,
                  //     fontWeight: task.isOverdue
                  //         ? FontWeight.w600
                  //         : FontWeight.normal,
                  //   ),
                  // ),

                  const Gap(6),

                  // Progress bar — inside the column
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: progressColor.withOpacity(0.12),
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
    );
  }

  String _statusLabel() {
    if (task.isCompleted) return 'Completed';
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
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Color _progressColor(double pct, bool overdue, ThemeData theme) {
    if (overdue) return theme.colorScheme.error;
    // if (pct >= 1.0) return const Color(0xFF4CAF50);
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
                color: Colors.black.withOpacity(0.35),
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
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultImage(size));
    }
    if (task.imageUrl != null) {
      return CachedNetworkImage(
          imageUrl: task.imageUrl!,
          width: size, height: size, fit: BoxFit.cover,
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




// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:intl/intl.dart';
//
// import '../../../domain/entities/task.dart';
//
// class TaskCard extends StatelessWidget {
//   final TodoTask task;
//   final VoidCallback onTap;
//   final VoidCallback onToggle;
//   final VoidCallback onDelete;
//
//   const TaskCard({
//     super.key,
//     required this.task,
//     required this.onTap,
//     required this.onToggle,
//     required this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final pct = task.completionPercentage / 100;
//     final progressColor = _progressColor(pct, task.isOverdue, theme);
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // ── Thumbnail ──────────────────────────────────
//                   _Thumbnail(task: task),
//                   const Gap(12),
//
//                   // ── Title + subtitle ───────────────────────────
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           task.title,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w700,
//                             decoration: task.isCompleted
//                                 ? TextDecoration.lineThrough
//                                 : null,
//                             color: task.isCompleted
//                                 ? theme.colorScheme.onSurfaceVariant
//                                 : theme.colorScheme.onSurface,
//                           ),
//                         ),
//                         const Gap(3),
//                         Row(
//                           children: [
//                             if (task.subtasks.isNotEmpty) ...
//                             [
//                               Text(
//                                 '${task.subtasks.length} subtask${task.subtasks.length > 1 ? 's' : ''}',
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: theme.colorScheme.onSurfaceVariant,
//                                 ),
//                               ),
//                               Text(
//                                 ' • ',
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                     color:
//                                     theme.colorScheme.onSurfaceVariant),
//                               ),
//                             ],
//                             Expanded(
//                               child: Text(
//                                 _statusLabel(),
//                                 overflow: TextOverflow.ellipsis,
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: task.isOverdue
//                                       ? theme.colorScheme.error
//                                       : task.isCompleted
//                                       ? theme.colorScheme.onSurfaceVariant
//                                       : theme.colorScheme.onSurfaceVariant,
//                                   fontWeight: task.isOverdue
//                                       ? FontWeight.w600
//                                       : FontWeight.normal,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const Gap(8),
//
//                   // ── Percentage ─────────────────────────────────
//                   Text(
//                     '${task.completionPercentage.round()}%',
//                     style: theme.textTheme.labelLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: progressColor,
//                     ),
//                   ),
//                 ],
//               ),
//
//               const Gap(10),
//
//               // ── Progress bar ───────────────────────────────────
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: LinearProgressIndicator(
//                   value: pct.clamp(0.0, 1.0),
//                   minHeight: 5,
//                   backgroundColor: progressColor.withOpacity(0.15),
//                   valueColor: AlwaysStoppedAnimation<Color>(progressColor),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _statusLabel() {
//     if (task.isCompleted) return 'Completed';
//     if (task.isOverdue) {
//       return 'Overdue · ${DateFormat('MMM d').format(task.dueDate!)}';
//     }
//     if (task.dueDate != null) {
//       return 'Due ${DateFormat('MMM d').format(task.dueDate!)}';
//     }
//     return _timeAgo(task.createdAt);
//   }
//
//   String _timeAgo(DateTime dt) {
//     final diff = DateTime.now().difference(dt);
//     if (diff.inDays > 0) return '${diff.inDays} days ago';
//     if (diff.inHours > 0) return '${diff.inHours}h ago';
//     return 'Just now';
//   }
//
//   Color _progressColor(double pct, bool overdue, ThemeData theme) {
//     if (overdue) return theme.colorScheme.error;
//     if (pct >= 1.0) return const Color(0xFF4CAF50); // green
//     if (pct >= 0.5) return Colors.orange;
//     return const Color(0xFF3D6FFF); // blue
//   }
// }
//
// // ─── Thumbnail ────────────────────────────────────────────────────────────────
// // Always shows an image. When task is completed, applies a muted grey overlay
// // with a centred white checkmark — matching the mockup exactly.
//
// class _Thumbnail extends StatelessWidget {
//   final TodoTask task;
//   const _Thumbnail({required this.task});
//
//   @override
//   Widget build(BuildContext context) {
//     const size = 52.0;
//     const radius = BorderRadius.all(Radius.circular(12));
//
//     return ClipRRect(
//       borderRadius: radius,
//       child: SizedBox(
//         width: size,
//         height: size,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // ── Image layer ──────────────────────────────────────
//             _imageWidget(size),
//
//             // ── Completed overlay: muted + checkmark ─────────────
//             if (task.isCompleted)
//               Container(
//                 color: Colors.black.withOpacity(0.35),
//                 child: const Center(
//                   child: Icon(
//                     Icons.check_rounded,
//                     color: Colors.white,
//                     size: 26,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _imageWidget(double size) {
//     if (task.imagePath != null) {
//       return Image.file(
//         File(task.imagePath!),
//         width: size,
//         height: size,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => _defaultImage(size),
//       );
//     }
//     if (task.imageUrl != null) {
//       return CachedNetworkImage(
//         imageUrl: task.imageUrl!,
//         width: size,
//         height: size,
//         fit: BoxFit.cover,
//         errorWidget: (_, __, ___) => _defaultImage(size),
//       );
//     }
//     return _defaultImage(size);
//   }
//
//   Widget _defaultImage(double size) {
//     return Image.asset(
//       'assets/images/default_task.png',
//       width: size,
//       height: size,
//       fit: BoxFit.cover,
//     );
//   }
// }
//
// // ─── Priority Badge ───────────────────────────────────────────────────────────
//
// class _PriorityBadge extends StatelessWidget {
//   final TaskPriority priority;
//   const _PriorityBadge({required this.priority});
//
//   @override
//   Widget build(BuildContext context) {
//     final (color, label) = switch (priority) {
//       TaskPriority.high => (Colors.red.shade400, 'High'),
//       TaskPriority.medium => (Colors.orange.shade400, 'Med'),
//       TaskPriority.low => (Colors.green.shade400, 'Low'),
//     };
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.4)),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//             fontSize: 10, fontWeight: FontWeight.w700, color: color),
//       ),
//     );
//   }
// }
//
//
//
//
