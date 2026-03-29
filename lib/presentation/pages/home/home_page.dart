// Home page — main task list with filter bar, backup and create actions.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/usecases/task/create_task_usecase.dart';
import '../../state/task_list_notifier.dart';
import '../../providers/providers.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_list.dart';
import '../../widgets/task/task_form_sheet.dart';
import '../../widgets/task/task_detail_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskFlow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Export Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            activeFilter: _activeFilter,
            onFilterChanged: (f) {
              setState(() => _activeFilter = f);
              ref.read(taskListProvider.notifier).setFilter(f);
            },
          ),
          Expanded(
            child: switch (state) {
              TaskListLoading() => const ShimmerList(),
              TaskListError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const Gap(12),
                    Text(message),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(taskListProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              TaskListLoaded(:final filteredTasks) => filteredTasks.isEmpty
                  ? const EmptyState()
                  : _TaskList(tasks: filteredTasks),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ).animate().slideY(begin: 2, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => TaskFormSheet(
        title: '✨ Create New Todo',
        onSubmit: (title, description, imagePath, imageUrl, dueDate, priority) {
          ref.read(taskListProvider.notifier).createTask(
            CreateTaskParams(
              title: title,
              description: description,
              imagePath: imagePath,
              imageUrl: imageUrl,
              dueDate: dueDate,
              priority: priority,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'export') {
      await _exportBackup();
    } else if (action == 'import') {
      await _importBackup();
    }
  }

  Future<void> _exportBackup() async {
    final result = await ref.read(exportBackupUseCaseProvider).call();
    result.fold(
      ok: (bytes) async {
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/taskflow_backup${AppConstants.backupFileExtension}');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], subject: 'TaskFlow Backup');
      },
      err: (e) => _showSnack('Export failed: $e'),
    );
  }

  Future<void> _importBackup() async {
    final picked = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.first.bytes ??
        await File(picked.files.first.path!).readAsBytes();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content:
        const Text('This will replace ALL current tasks. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true) return;

    final result =
    await ref.read(importBackupUseCaseProvider).call(bytes.toList());
    result.fold(
      ok: (_) {
        ref.read(taskListProvider.notifier).load();
        _showSnack('Backup restored successfully!');
      },
      err: (e) => _showSnack('Import failed: $e'),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── Task List ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  final List<Task> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        return TaskCard(
          task: task,
          onTap: () => _openDetail(context, ref, task),
          onToggle: () =>
              ref.read(taskListProvider.notifier).toggleCompletion(task.id),
          onDelete: () => _confirmDelete(context, ref, task),
        )
            .animate(delay: (i * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05);
      },
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => TaskDetailSheet(taskId: task.id),
    ).then((_) => ref.read(taskListProvider.notifier).load());
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
            '"${task.title}" and all its subtasks will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(taskListProvider.notifier).deleteTask(task.id);
    }
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  const _FilterBar(
      {required this.activeFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip('All', null),
          const Gap(8),
          _chip('Active', 'active'),
          const Gap(8),
          _chip('Done', 'completed'),
        ],
      ),
    );
  }

  Widget _chip(String label, String? filter) {
    return FilterChip(
      label: Text(label),
      selected: activeFilter == filter,
      onSelected: (_) => onFilterChanged(filter),
    );
  }
}