// Home page — main task list with filter bar, backup and create actions.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimens.dart';
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
    final state  = ref.watch(taskListProvider);
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header SliverAppBar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: AppDimens.headerExpandedH,
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeaderBanner(state: state, isDark: isDark),
            ),
            actions: [
              // Theme toggle
              Container(
                margin: const EdgeInsets.only(right: AppDimens.appBarBtnMarginR),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimens.appBarBtnRadius),
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: AppDimens.appBarIconSize,
                  ),
                  tooltip: AppStrings.toggleTheme,
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ),
              // Backup menu
              Container(
                margin: const EdgeInsets.only(right: AppDimens.appBarBtnMarginRLast),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimens.appBarBtnRadius),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: AppDimens.appBarIconSize),
                  offset: const Offset(0, AppDimens.appBarMenuOffset),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.appBarMenuRadius)),
                  onSelected: _handleMenuAction,
                  itemBuilder: (ctx) => [
                    _menuItem('export', Icons.upload_rounded,
                        AppStrings.exportBackup),
                    _menuItem('import', Icons.download_rounded,
                        AppStrings.importBackup),
                  ],
                ),
              ),
            ],
          ),

          // ── Filter bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              activeFilter: _activeFilter,
              state: state,
              onFilterChanged: (f) {
                setState(() => _activeFilter = f);
                ref.read(taskListProvider.notifier).setFilter(f);
              },
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          switch (state) {
            TaskListLoading() =>
              const SliverFillRemaining(child: ShimmerList()),
            TaskListError(:final message) => SliverFillRemaining(
                child: _ErrorView(
                  message: message,
                  onRetry: () => ref.read(taskListProvider.notifier).retry(),
                ),
              ),
            TaskListLoaded(:final filteredTasks, :final filter) =>
              filteredTasks.isEmpty
                  ? SliverFillRemaining(
                      child: filter == null
                          ? const EmptyState()
                          : _FilterEmptyState(filter: filter),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDimens.pagePadH, AppDimens.spaceXs,
                          AppDimens.pagePadH, AppDimens.listBottomPad),
                      sliver: SliverList.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (ctx, i) {
                          final task = filteredTasks[i];
                          return TaskCard(
                            task: task,
                            onTap: () => _openDetail(context, ref, task),
                            onToggle: () => ref
                                .read(taskListProvider.notifier)
                                .toggleCompletion(task.id),
                            onDelete: () => _confirmDelete(context, ref, task),
                          )
                              .animate(delay: (i * 40).ms)
                              .fadeIn(duration: 280.ms)
                              .slideX(begin: 0.04, curve: Curves.easeOut);
                        },
                      ),
                    ),
          },
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          AppStrings.newTask,
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        elevation: 6,
      )
          .animate()
          .slideY(begin: 2, duration: 450.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 300.ms),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: AppDimens.iconLg),
        const Gap(AppDimens.spaceLg),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => TaskFormSheet(
        title: AppStrings.createTaskTitle,
        onSubmit: (title, desc, imagePath, imageUrl, dueDate, priority) {
          ref.read(taskListProvider.notifier).createTask(
                CreateTaskParams(
                  title: title,
                  description: desc,
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
    if (action == 'export') await _exportBackup();
    if (action == 'import') await _importBackup();
  }

  Future<void> _exportBackup() async {
    final result = await ref.read(exportBackupUseCaseProvider).call();
    result.fold(
      ok: (bytes) async {
        final dir  = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/${AppStrings.appName.toLowerCase()}_backup'
            '${AppConstants.backupFileExtension}');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)],
            subject: '${AppStrings.appName} Backup');
      },
      err: (e) => _showSnack('${AppStrings.exportFailed}$e'),
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
        title: const Text(AppStrings.restoreBackupTitle),
        content: const Text(AppStrings.restoreBackupContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.btnCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.btnRestore)),
        ],
      ),
    );
    if (ok != true) return;

    final result =
        await ref.read(importBackupUseCaseProvider).call(bytes.toList());
    result.fold(
      ok: (_) {
        ref.read(taskListProvider.notifier).load();
        _showSnack(AppStrings.restoreSuccess);
      },
      err: (e) => _showSnack('${AppStrings.importFailed}$e'),
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
        title: const Text(AppStrings.deleteTaskTitle),
        content: Text(
            '"${task.title}${AppStrings.deleteTaskSuffix}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.btnCancel)),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.btnDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(taskListProvider.notifier).deleteTask(task.id);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── Header Banner ────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final TaskListState state;
  final bool isDark;
  const _HeaderBanner({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total  = state is TaskListLoaded
        ? (state as TaskListLoaded).tasks.length : 0;
    final done   = state is TaskListLoaded
        ? (state as TaskListLoaded).tasks.where((t) => t.isCompleted).length : 0;
    final active = total - done;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadV, 56, AppDimens.pagePadV, AppDimens.pagePadH),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1C1B2E), const Color(0xFF252438)]
              : [const Color(0xFFF5F4FF), const Color(0xFFEEECFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Title ──────────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppStrings.appName,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: isDark
                        ? const Color(0xFFE8E6FF)
                        : const Color(0xFF1C1B2E),
                  ),
                ),
                TextSpan(
                  text: ' ✦',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppDimens.spaceSm - 1),
          Text(
            total == 0
                ? AppStrings.appTagline
                : '$active ${AppStrings.filterActive.toLowerCase()} · $done ${AppStrings.filterDone.toLowerCase()}',
            style: TextStyle(
              fontSize: AppDimens.fontBase,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFABA9C3)
                  : const Color(0xFF7B7A8F),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? activeFilter;
  final TaskListState state;
  final ValueChanged<String?> onFilterChanged;

  const _FilterBar({
    required this.activeFilter,
    required this.state,
    required this.onFilterChanged,
  });

  int _count(String? filter) {
    if (state is! TaskListLoaded) return 0;
    final tasks = (state as TaskListLoaded).tasks;
    return switch (filter) {
      'active'    => tasks.where((t) => !t.isCompleted).length,
      'completed' => tasks.where((t) => t.isCompleted).length,
      _           => tasks.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, AppDimens.spaceXl,
          AppDimens.pagePadH, AppDimens.spaceXs),
      child: Row(
        children: [
          _FilterChip(
            label: AppStrings.filterAll,
            count: _count(null),
            selected: activeFilter == null,
            onTap: () => onFilterChanged(null),
            theme: theme,
          ),
          const Gap(AppDimens.spaceMd),
          _FilterChip(
            label: AppStrings.filterActive,
            count: _count('active'),
            selected: activeFilter == 'active',
            onTap: () => onFilterChanged('active'),
            theme: theme,
            activeColor: AppTheme.primaryColor,
          ),
          const Gap(AppDimens.spaceMd),
          _FilterChip(
            label: AppStrings.filterDone,
            count: _count('completed'),
            selected: activeFilter == 'completed',
            onTap: () => onFilterChanged('completed'),
            theme: theme,
            activeColor: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? activeColor;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.theme,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color  = activeColor ?? AppTheme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pagePadH,
            vertical: AppDimens.filterChipHeight),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? const Color(0xFF252438) : const Color(0xFFF0EFFE)),
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
          boxShadow: selected
              ? [BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: AppDimens.spaceMd,
                  offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppDimens.fontBase,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            if (count > 0) ...[
              const Gap(AppDimens.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.filterBadgePadH,
                    vertical: AppDimens.filterBadgePadV),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusChip),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: AppDimens.fontSm,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Filter Empty State ───────────────────────────────────────────────────────

class _FilterEmptyState extends StatelessWidget {
  final String filter;
  const _FilterEmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final isActive = filter == 'active';
    final icon     = isActive
        ? Icons.radio_button_unchecked_rounded
        : Icons.check_circle_outline_rounded;
    final color    = isActive ? AppTheme.primaryColor : AppTheme.successGreen;
    final title    = isActive ? AppStrings.noActiveTasks : AppStrings.noCompletedTasks;
    final subtitle = isActive ? AppStrings.noActiveSubtitle : AppStrings.noCompletedSubtitle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppDimens.iconHero + 8, color: color),
            ),
            const Gap(AppDimens.space24),
            Text(title,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const Gap(AppDimens.spaceLg),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.55)),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.pagePadV),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: AppDimens.iconHero, color: theme.colorScheme.error),
            ),
            const Gap(AppDimens.pagePadV),
            Text(AppStrings.errorTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Gap(AppDimens.spaceMd),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const Gap(AppDimens.pagePadV),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  size: AppDimens.iconLg + 4),
              label: const Text(AppStrings.errorRetry),
            ),
          ],
        ),
      ),
    );
  }
}

