import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/task.dart';
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
              'Back',
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
        TaskDetailLoaded(:final task) => _TaskDetailContent(
          task: task,
          notifier: ref.read(taskDetailProvider(taskId).notifier),
          depth: depth,
        ),
      },
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _TaskDetailContent extends ConsumerWidget {
  final Task task;
  final TaskDetailNotifier notifier;
  final int depth;
  const _TaskDetailContent({required this.task, required this.notifier, this.depth = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                      const Gap(6),
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

                    const Gap(20),

                    // Completion status card
                    _CompletionCard(task: task, notifier: notifier),

                    const Gap(12),

                    // Meta card
                    _MetaCard(task: task),

                    const Gap(24),

                    // Subtasks header
                    _SubtasksHeader(task: task, notifier: notifier),

                    const Gap(10),
                  ]),
                ),
              ),

              // ── Subtask rows ────────────────────────────────────
              if (task.subtasks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList.builder(
                    itemCount: task.subtasks.length,
                    itemBuilder: (ctx, i) {
                      final sub = task.subtasks[i];
                      return _SubtaskRow(
                        subtask: sub,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => _TaskDetailPage(
                              taskId: sub.id,
                              depth: depth + 1,
                            ),
                          ),
                        ),
                        onToggle: () => notifier.toggleCompletion(sub.id),
                        onDelete: () => _confirmDelete(context, sub),
                      )
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.04);
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      task.depth < 4
                          ? 'No subtasks yet. Tap Add to create one.'
                          : 'No subtasks.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: Gap(120)),
            ],
          ),
        ),

        // ── Bottom action bar ─────────────────────────────────────
        _BottomActionBar(task: task, notifier: notifier),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Task sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subtask?'),
        content:
        Text('"${sub.title}" and all its subtasks will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteSubtask(sub.id);
            },
            child: const Text('Delete'),
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        height: 220,
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
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultCentered());
    }
    if (task.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: task.imageUrl!,
        width: double.infinity,
        height: 220,
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
      width: 110,
      height: 110,
      fit: BoxFit.contain,
    ),
  );
}

// ─── Completion Status Card ───────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final Task task;
  final TaskDetailNotifier notifier;
  const _CompletionCard({required this.task, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = task.completionPercentage / 100;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.55)
        : const Color(0xFFF0F0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'COMPLETION STATUS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(4),

          // Percentage
          Text(
            '${task.completionPercentage.round()}%',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D6FFF),
            ),
          ),
          const Gap(8),

          // Progress bar — green as in mockup
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.green.withOpacity(0.15),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const Gap(8),

          // Subtask count
          if (task.subtasks.isNotEmpty)
            Text(
              '${task.completedSubtaskCount} of ${task.totalSubtaskCount} subtasks completed',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),

          // Leaf slider (bonus)
          if (task.subtasks.isEmpty) ...[
            Slider(
              value: task.manualCompletionPercent,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: const Color(0xFF3D6FFF),
              label: '${task.manualCompletionPercent.round()}%',
              onChanged: (v) =>
                  notifier.updateCompletionPercent(task.id, v),
            ),
            Text(
              'Drag to set partial completion',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],

          // Completed date
          if (task.completedAt != null) ...[
            const Gap(6),
            Row(children: [
              Icon(Icons.check_circle, size: 13, color: Colors.green.shade600),
              const Gap(4),
              Text(
                'Completed ${DateFormat('MMM d, yyyy').format(task.completedAt!)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.green.shade600),
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
        ? theme.colorScheme.surfaceVariant.withOpacity(0.55)
        : const Color(0xFFF0F0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRow('📅', 'Created: ${DateFormat('MMM d, yyyy').format(task.createdAt)}', theme),
          const Gap(5),
          _metaRow('✏️', 'Modified: ${DateFormat('MMM d, yyyy').format(task.updatedAt)}', theme),
          if (task.dueDate != null) ...[
            const Gap(5),
            _metaRow(
              task.isOverdue ? '🔴' : '🗓️',
              'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate!)}${task.isOverdue ? ' · Overdue' : ''}',
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
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const Gap(8),
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
          'SUBTASKS (${task.subtasks.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (task.depth < 4)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Add'),
            onPressed: () => _showAddSubtask(context),
          ),
      ],
    );
  }

  void _showAddSubtask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(
        title: 'Add Subtask',
        onSubmit: (title, desc, imagePath, dueDate, priority) =>
            notifier.addSubtask(title, desc),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceVariant.withOpacity(0.35)
              : const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Animated checkbox
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: completed ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? Colors.green
                        : theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: completed
                    ? const Icon(Icons.check,
                    size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const Gap(14),

            // Title + progress label
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
                  const Gap(2),
                  Text(
                    completed
                        ? 'Completed'
                        : subtask.subtasks.isEmpty
                        ? '0 of 0 completed'
                        : '$completedCount of $totalCount completed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: completed
                          ? Colors.green.shade600
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant),
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
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Btn(
              label: '✏️  Edit',
              color: const Color(0xFF3D6FFF),
              onTap: () => _showEdit(context),
            ),
          ),
          const Gap(8),
          Expanded(
            child: _Btn(
              label: task.isCompleted ? '↩  Undo' : '✓  Complete',
              color: Colors.green.shade600,
              onTap: () => notifier.toggleCompletion(task.id),
            ),
          ),
          const Gap(8),
          Expanded(
            child: _Btn(
              label: '🗑  Delete',
              color: Colors.red.shade500,
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
      builder: (_) => TaskFormSheet(
        title: 'Edit Task',
        initialTitle: task.title,
        initialDescription: task.description,
        initialImagePath: task.imagePath,
        initialDueDate: task.dueDate,
        initialPriority: task.priority,
        onSubmit: (title, desc, imagePath, dueDate, priority) {
          notifier.updateTask(task.copyWith(
            title: title,
            description: desc,
            imagePath: imagePath,
            dueDate: dueDate,
            priority: priority,
            clearImagePath: imagePath == null,
          ));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
            '"${task.title}" and all its subtasks will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor:
                Theme.of(ctx).colorScheme.errorContainer),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
              notifier.deleteSubtask(task.id);
            },
            child: const Text('Delete'),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}