import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/task.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../state/task_detail_notifier.dart';
import '../common/shimmer_list.dart';
import 'task_form_sheet.dart';

/// Bottom sheet with its own independent Navigator — satisfies nested nav stack requirement.
/// [PopScope] intercepts the Android back button:
///   - If the modal navigator has pages to pop → go back one level inside the modal.
///   - If at root level → allow the bottom sheet itself to close.
class TaskDetailSheet extends StatefulWidget {
  final String taskId;
  const TaskDetailSheet({super.key, required this.taskId});

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop = false means we handle the back ourselves
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          // Go back one level inside the modal navigator
          nav.pop();
        } else {
          // At root — close the bottom sheet
          Navigator.of(context).pop();
        }
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => _TaskDetailPage(taskId: widget.taskId),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailPage extends ConsumerWidget {
  final String taskId;
  final int depth; // used to show back button when depth > 1

  const _TaskDetailPage({required this.taskId, this.depth = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(taskId));
    // canPop is true when we're inside the modal navigator (depth > 1)
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      // Back button row shown whenever modal navigator has a previous route
      appBar: canPop
          ? AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(
              AppStrings.btnBack,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          : null,
      body: switch (state) {
        TaskDetailLoading() => const ShimmerList(),
        TaskDetailError(:final message) => Center(child: Text(message)),
        TaskDetailLoaded() => _TaskDetailContent(
          taskId: taskId,
          depth: depth,
        ),
      },
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _TaskDetailContent extends ConsumerWidget {
  final String taskId; // watch by ID, not by stale task prop
  final int depth;
  const _TaskDetailContent({required this.taskId, this.depth = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always watch — so any mutation (delete, toggle, update) triggers a rebuild
    final state    = ref.watch(taskDetailProvider(taskId));
    final notifier = ref.read(taskDetailProvider(taskId).notifier);

    // Still loading or errored after a mutation — show appropriate widget
    if (state is TaskDetailLoading) return const ShimmerList();
    if (state is TaskDetailError) {
      return Center(child: Text(state.message));
    }

    final task = (state as TaskDetailLoaded).task;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Hero image — full width, edge to edge ──────────
              SliverToBoxAdapter(
                child: _HeroImage(task: task)
                    .animate()
                    .fadeIn(duration: 300.ms),
              ),

              // ── Body content ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadV, AppDimens.pagePadV,
                    AppDimens.pagePadV, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(
                      task.title,
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

                    // Description
                    if (task.description?.isNotEmpty == true) ...[
                      const Gap(AppDimens.spaceSm),
                      Text(
                        task.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],

                    const Gap(AppDimens.pagePadV),

                    // Completion status card
                    _CompletionCard(task: task, notifier: notifier),

                    const Gap(AppDimens.spaceXl),

                    // Meta card
                    _MetaCard(task: task),

                    const Gap(AppDimens.space24),

                    // Subtasks header
                    _SubtasksHeader(task: task, notifier: notifier),

                    const Gap(AppDimens.spaceLg),
                  ]),
                ),
              ),

              // ── Subtask rows ────────────────────────────────────
              if (task.subtasks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadV, 0, AppDimens.pagePadV, 0),
                  sliver: SliverList.builder(
                    itemCount: task.subtasks.length,
                    itemBuilder: (ctx, i) {
                      final sub = task.subtasks[i];
                      return _SubtaskRow(
                        subtask: sub,
                        onTap: () async {
                          await Navigator.of(ctx).push(
                            MaterialPageRoute(
                              builder: (_) => _TaskDetailPage(
                                taskId: sub.id,
                                depth: depth + 1,
                              ),
                            ),
                          );
                          // Reload after returning from child so parent
                          // completion % reflects any changes made there
                          notifier.load();
                        },
                        onToggle: () => notifier.toggleCompletion(sub.id),
                        onDelete: () => _confirmDelete(context, sub, notifier),
                      )
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.04);
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadV, 0, AppDimens.pagePadV, 0),
                  sliver: SliverToBoxAdapter(
                      child: Text(
                      task.depth < 4
                          ? AppStrings.noSubtasksYet
                          : AppStrings.noSubtasksMaxDepth,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: Gap(AppDimens.listBottomPad)),
            ],
          ),
        ),

        // ── Bottom action bar ─────────────────────────────────────
        _BottomActionBar(task: task, notifier: notifier),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Task sub, TaskDetailNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteSubtaskTitle),
        content: Text('"${sub.title}${AppStrings.deleteSubtaskSuffix}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.btnCancel)),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteSubtask(sub.id);
            },
            child: const Text(AppStrings.btnDelete),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Image ───────────────────────────────────────────────────────────────
// Full width, rounded top corners only (matches bottom sheet),
// purple-to-indigo gradient background, default icon centred.

class _HeroImage extends StatelessWidget {
  final Task task;
  const _HeroImage({required this.task});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusSheet)),
      child: Container(
        width: double.infinity,
        height: AppDimens.heroImageHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5B6EE8), Color(0xFF8B5CF6)],
          ),
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (task.imagePath != null) {
      return Image.file(File(task.imagePath!),
          width: double.infinity,
          height: AppDimens.heroImageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultCentered());
    }
    if (task.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: task.imageUrl!,
        width: double.infinity,
        height: AppDimens.heroImageHeight,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) => _defaultCentered(),
      );
    }
    return _defaultCentered();
  }

  Widget _defaultCentered() => Center(
    child: Image.asset(
      'assets/images/default_task.png',
      width: AppDimens.subDetailRowH / 2,
      height: AppDimens.subDetailRowH / 2,
      fit: BoxFit.contain,
    ),
  );
}

// ─── Completion Status Card ───────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final Task task;
  final TaskDetailNotifier notifier;
  const _CompletionCard({required this.task, required this.notifier});

  Color _progressColor(double pct, ThemeData theme) {
    if (task.isOverdue) return theme.colorScheme.error;
    if (pct >= 1.0) return AppTheme.successGreen;
    if (pct >= 0.5) return AppTheme.warningOrange;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final pct     = (task.completionPercentage / 100).clamp(0.0, 1.0);
    final color   = _progressColor(pct, theme);
    final isDark  = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : const Color(0xFFF0F0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.pagePadH),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.completionStatusLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppDimens.spaceXs),

          Text(
            '${task.completionPercentage.round()}%',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(AppDimens.spaceMd),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.progressBarRadius),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: AppDimens.progressBarHeightLg,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const Gap(AppDimens.spaceMd),

          if (task.subtasks.isNotEmpty)
            Text(
              '${task.completedSubtaskCount}${AppStrings.subtaskOf}${task.totalSubtaskCount} subtasks${AppStrings.subtaskCompletedSuffix}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            )
          else ...[
            Slider(
              value: task.manualCompletionPercent,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: color,
              label: '${task.manualCompletionPercent.round()}%',
              onChanged: (v) => notifier.updateCompletionPercent(task.id, v),
            ),
            Text(
              AppStrings.dragToSetCompletion,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],

          if (task.completedAt != null) ...[
            const Gap(AppDimens.spaceSm),
            Row(children: [
              Icon(Icons.check_circle,
                  size: AppDimens.fontBase, color: color),
              const Gap(AppDimens.spaceXs),
              Text(
                '${AppStrings.metaCompleted}${DateFormat('MMM d, yyyy').format(task.completedAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ─── Meta Card ────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final Task task;
  const _MetaCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : const Color(0xFFF0F0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.pagePadH,
          vertical: AppDimens.spaceXl),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRow('📅', '${AppStrings.metaCreated}${DateFormat('MMM d, yyyy').format(task.createdAt)}', theme),
          const Gap(AppDimens.spaceSm - 1),
          _metaRow('✏️', '${AppStrings.metaModified}${DateFormat('MMM d, yyyy').format(task.updatedAt)}', theme),
          if (task.dueDate != null) ...[
            const Gap(AppDimens.spaceSm - 1),
            _metaRow(
              task.isOverdue ? '🔴' : '🗓️',
              '${AppStrings.metaDue}${DateFormat('MMM d, yyyy').format(task.dueDate!)}${task.isOverdue ? AppStrings.metaOverdue : ''}',
              theme,
              color: task.isOverdue ? theme.colorScheme.error : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(String emoji, String text, ThemeData theme,
      {Color? color}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: AppDimens.fontLg)),
        const Gap(AppDimens.spaceMd),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            fontWeight:
            color != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Subtasks Header ──────────────────────────────────────────────────────────

class _SubtasksHeader extends StatelessWidget {
  final Task task;
  final TaskDetailNotifier notifier;
  const _SubtasksHeader({required this.task, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${AppStrings.subtasksHeader} (${task.subtasks.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (task.depth < 4)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline,
                size: AppDimens.pagePadH),
            label: const Text(AppStrings.btnAdd),
            onPressed: () => _showAddSubtask(context),
          ),
      ],
    );
  }

  void _showAddSubtask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskFormSheet(
        title: AppStrings.addSubtaskTitle,
        onSubmit: (title, desc, imagePath, imageUrl, dueDate, priority) =>
            notifier.addSubtask(
          title,
          desc,
          imagePath: imagePath,
          imageUrl: imageUrl,
          dueDate: dueDate,
          priority: priority,
        ),
      ),
    );
  }
}

// ─── Subtask Row ──────────────────────────────────────────────────────────────

class _SubtaskRow extends StatelessWidget {
  final Task subtask;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskRow({
    required this.subtask,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completed = subtask.isCompleted;
    final completedCount = subtask.completedSubtaskCount;
    final totalCount = subtask.totalSubtaskCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.spaceLg),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.cardPad,
            vertical: AppDimens.cardPad),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35)
              : const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: completed ? AppTheme.successGreen : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? AppTheme.successGreen
                        : theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.spaceSm),
                ),
                child: completed
                    ? Icon(Icons.check,
                        size: AppDimens.pagePadH, color: Colors.white)
                    : null,
              ),
            ),
            const Gap(AppDimens.cardPad),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtask.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                      color: completed
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Gap(AppDimens.spaceXxs),
                  Text(
                    completed
                        ? AppStrings.subtaskCompleted
                        : subtask.subtasks.isEmpty
                            ? '${subtask.completionPercentage.round()}${AppStrings.subtaskPercentSuffix}'
                            : '$completedCount${AppStrings.subtaskOf}$totalCount${AppStrings.subtaskCompletedSuffix}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: completed
                          ? AppTheme.successGreen
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward_ios,
                    size: AppDimens.iconSm,
                    color: theme.colorScheme.onSurfaceVariant),
                const Gap(AppDimens.spaceSm),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline,
                      size: AppDimens.iconLg,
                      color:
                          theme.colorScheme.error.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final Task task;
  final TaskDetailNotifier notifier;
  const _BottomActionBar({required this.task, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadH,
        AppDimens.spaceXl,
        AppDimens.pagePadH,
        MediaQuery.paddingOf(context).bottom + AppDimens.spaceXl,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Btn(
              label: AppStrings.btnEdit,
              color: AppTheme.primaryColor,
              onTap: () => _showEdit(context),
            ),
          ),
          const Gap(AppDimens.spaceMd),
          Expanded(
            child: _Btn(
              label: task.isCompleted
                  ? AppStrings.btnUndo
                  : AppStrings.btnComplete,
              color: AppTheme.successGreen,
              onTap: () => notifier.toggleCompletion(task.id),
            ),
          ),
          const Gap(AppDimens.spaceMd),
          Expanded(
            child: _Btn(
              label: AppStrings.btnDelete,
              color: Theme.of(context).colorScheme.error,
              onTap: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskFormSheet(
        title: AppStrings.editTaskTitle,
        initialTitle: task.title,
        initialDescription: task.description,
        initialImagePath: task.imagePath,
        initialImageUrl: task.imageUrl,
        initialDueDate: task.dueDate,
        initialPriority: task.priority,
        onSubmit: (title, desc, imagePath, imageUrl, dueDate, priority) {
          notifier.updateTask(task.copyWith(
            title: title,
            description: desc,
            imagePath: imagePath,
            imageUrl: imageUrl,
            dueDate: dueDate,
            priority: priority,
            clearImagePath: imagePath == null && imageUrl == null,
            clearImageUrl: imageUrl == null,
          ));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final sheetNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteTaskTitle),
        content: Text('"${task.title}${AppStrings.deleteTaskSuffix}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.btnCancel)),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.errorContainer),
            onPressed: () async {
              Navigator.pop(ctx);   // close dialog
              sheetNavigator.pop(); // close sheet — widget gone before delete
              // Delete without calling load() — the sheet is already dismissed
              await notifier.deleteWithoutReload(task.id);
            },
            child: const Text(AppStrings.btnDelete),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppDimens.actionBtnRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.actionBtnRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.pagePadH),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppDimens.fontLg,
            ),
          ),
        ),
      ),
    );
  }
}






