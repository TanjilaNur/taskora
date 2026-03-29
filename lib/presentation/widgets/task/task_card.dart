import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimens.dart';
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
    final priorityColor = _priorityColor(task.priority);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.space24),
        margin: const EdgeInsets.only(bottom: AppDimens.spaceXl),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded,
                color: theme.colorScheme.error, size: AppDimens.iconXxl),
            const Gap(AppDimens.spaceXs),
            Text(AppStrings.btnDelete,
                style: TextStyle(
                    fontSize: AppDimens.fontSm,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimens.spaceXl),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1B2E) : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
                      blurRadius: AppDimens.spaceXl,
                      offset: const Offset(0, AppDimens.spaceXs),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // ── Main row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.cardPad, AppDimens.cardPad,
                    AppDimens.cardPad, AppDimens.spaceLg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Priority dot + Thumbnail ───────────────────────
                    Stack(
                      children: [
                        _Thumbnail(task: task),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: AppDimens.priorityDot,
                            height: AppDimens.priorityDot,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1C1B2E)
                                    : Colors.white,
                                width: AppDimens.priorityDotBorder,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppDimens.spaceXl),

                    // ── Text content ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + % badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppDimens.fontLg,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor:
                                        theme.colorScheme.onSurfaceVariant,
                                    color: task.isCompleted
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.onSurface,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const Gap(AppDimens.spaceMd),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.spaceMd,
                                    vertical: AppDimens.spaceXxs + 1),
                                decoration: BoxDecoration(
                                  color: progressColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusChip),
                                ),
                                child: Text(
                                  '${task.completionPercentage.round()}%',
                                  style: TextStyle(
                                    fontSize: AppDimens.fontSm,
                                    fontWeight: FontWeight.w800,
                                    color: progressColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppDimens.spaceSm - 1),

                          // Meta row — subtask count + status + delete
                          Row(
                            children: [
                              if (task.subtasks.isNotEmpty) ...[
                                Icon(Icons.account_tree_outlined,
                                    size: AppDimens.iconXs,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7)),
                                const Gap(AppDimens.spaceXxs + 1),
                                Text(
                                  '${task.subtasks.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Gap(AppDimens.spaceMd),
                              ],
                              Expanded(
                                child: Text(
                                  _statusLabel(),
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: task.isOverdue
                                        ? theme.colorScheme.error
                                        : task.isCompleted
                                            ? AppTheme.successGreen
                                            : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: (task.isOverdue || task.isCompleted)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              // Delete button — circular tinted icon
                              const Gap(AppDimens.spaceSm),
                              GestureDetector(
                                onTap: onDelete,
                                child: Container(
                                  width: AppDimens.deleteButtonSize,
                                  height: AppDimens.deleteButtonSize,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withValues(
                                        alpha: isDark ? 0.15 : 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: AppDimens.iconMd,
                                    color: theme.colorScheme.error
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.cardPad, 0,
                    AppDimens.cardPad, AppDimens.cardPad),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimens.progressBarRadius),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: AppDimens.progressBarHeight,
                    backgroundColor: progressColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (task.isCompleted) {
      if (task.completedAt != null) {
        return '${AppStrings.statusCompleted} ${DateFormat('MMM d, yyyy').format(task.completedAt!)}';
      }
      return AppStrings.statusCompleted;
    }
    if (task.isOverdue) {
      return '${AppStrings.statusOverdue}${DateFormat('MMM d').format(task.dueDate!)}';
    }
    if (task.dueDate != null) {
      return '${AppStrings.statusDue}${DateFormat('MMM d').format(task.dueDate!)}';
    }
    return _timeAgo(task.createdAt);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return AppStrings.statusJustNow;
  }

  Color _progressColor(double pct, bool overdue, ThemeData theme) {
    if (overdue) return theme.colorScheme.error;
    if (pct >= 1.0) return AppTheme.successGreen;
    if (pct >= 0.5) return AppTheme.warningOrange;
    return AppTheme.primaryColor;
  }

  Color _priorityColor(TaskPriority priority) => switch (priority) {
        TaskPriority.high   => const Color(0xFFFF5252),
        TaskPriority.medium => AppTheme.warningOrange,
        TaskPriority.low    => AppTheme.successGreen,
      };
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final Task task;
  const _Thumbnail({required this.task});

  @override
  Widget build(BuildContext context) {
    const size = AppDimens.thumbnailCard;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.thumbnailCardRad),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imageWidget(size),
            if (task.isCompleted)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius:
                      BorderRadius.circular(AppDimens.thumbnailCardRad),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: AppDimens.iconXxl - 2),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(AppDimens.thumbnailCardRad),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/default_task.png',
          width: size * 0.6,
          height: size * 0.6,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.task_alt_rounded,
            color: Colors.white70,
            size: AppDimens.iconXxl,
          ),
        ),
      ),
    );
  }
}
