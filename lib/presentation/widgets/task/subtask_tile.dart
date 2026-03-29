import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/task.dart';

class SubtaskTile extends StatelessWidget {
  final Task subtask;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const SubtaskTile({
    super.key,
    required this.subtask,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = subtask.completionPercentage / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      subtask.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: subtask.isCompleted
                          ? Colors.green
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      subtask.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: subtask.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                  if (subtask.subtasks.isNotEmpty) ...[
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (subtask.subtasks.isNotEmpty) ...[
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: LinearPercentIndicator(
                        lineHeight: 6,
                        percent: pct.clamp(0.0, 1.0),
                        progressColor: pct >= 1.0 ? Colors.green : theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                        animation: true,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      '${(pct * 100).round()}%',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Gap(4),
                // Tap to expand hint
                Text(
                  '${subtask.subtasks.length} subtask${subtask.subtasks.length > 1 ? 's' : ''} · ${AppStrings.tapToExpand}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}