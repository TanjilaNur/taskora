/// All user-facing strings and static text in one place.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────────────────────
  static const String appName        = 'Taskora';
  static const String appTitle       = 'Taskora ✦';
  static const String appTagline     = 'No tasks yet — start fresh!';

  // ── Home page ──────────────────────────────────────────────────────────────
  static const String newTask        = 'New Task';
  static const String toggleTheme    = 'Toggle theme';
  static const String exportBackup   = 'Export Backup';
  static const String importBackup   = 'Import Backup';
  static const String exportFailed   = 'Export failed: ';
  static const String importFailed   = 'Import failed: ';
  static const String restoreSuccess = '✅ Backup restored successfully!';

  // ── Filter bar ─────────────────────────────────────────────────────────────
  static const String filterAll       = 'All';
  static const String filterActive    = 'Active';
  static const String filterDone      = 'Done';

  // ── Filter empty states ────────────────────────────────────────────────────
  static const String noActiveTasks        = 'No active tasks';
  static const String noActiveSubtitle     = 'All your tasks are done.\nGreat work! 🎉';
  static const String noCompletedTasks     = 'No completed tasks';
  static const String noCompletedSubtitle  = 'You haven\'t completed any tasks yet.\nKeep going! 💪';

  // ── Empty state ────────────────────────────────────────────────────────────
  static const String emptyTitle    = 'All clear!';
  static const String emptySubtitle = 'You have no tasks yet.\nTap  +  New Task  to get started.';

  // ── Error state ────────────────────────────────────────────────────────────
  static const String errorTitle    = 'Something went wrong';
  static const String errorRetry    = 'Try Again';

  // ── Task form sheet ────────────────────────────────────────────────────────
  static const String createTaskTitle      = '✨ Create New Task';
  static const String addSubtaskTitle      = 'Add Subtask';
  static const String editTaskTitle        = 'Edit Task';
  static const String labelThumbnail       = '📷 Upload Thumbnail (250×250px)';
  static const String labelImageUrl        = '🔗 Or paste an image URL';
  static const String labelTaskTitle       = '📝 Task Title *';
  static const String labelDescription     = '📄 Description';
  static const String labelDueDate         = '📅 Due Date (Optional)';
  static const String labelPriority        = '🎯 Priority';
  static const String hintTaskTitle        = 'Enter task title';
  static const String hintDescription      = 'Add a description (optional)';
  static const String hintImageUrl         = 'https://example.com/image.jpg';
  static const String hintDueDate          = 'Select a due date';
  static const String btnSaveTask          = 'Save Task';
  static const String btnSaveChanges       = 'Save Changes';
  static const String btnCancel            = 'Cancel';
  static const String btnUse               = 'Use';
  static const String btnChange            = 'Change';
  static const String validationTitleEmpty = 'Title is required';
  static const String imagePickGallery     = 'Choose from Gallery';
  static const String imagePickCamera      = 'Take a Photo';
  static const String imageUrlSet          = 'URL set: ';
  static const String imageUrlSetting      = 'Image URL set — will be downloaded on save';
  static const String imageUrlSaved        = 'URL saved (could not verify — will try on save)';
  static const String imageUrlInvalid      = 'Please enter a valid URL';
  static const String imageUrlUnreachable  = 'URL not reachable (';
  static const String tapToSelect          = 'Tap to select or take a photo';

  // ── Task detail sheet ──────────────────────────────────────────────────────
  static const String btnBack               = 'Back';
  static const String btnEdit               = '✏️  Edit';
  static const String btnComplete           = '✓  Complete';
  static const String btnUndo               = '↩  Undo';
  static const String btnDelete             = '🗑  Delete';
  static const String btnAdd                = 'Add';
  static const String completionStatusLabel = 'COMPLETION STATUS';
  static const String subtasksHeader        = 'SUBTASKS';
  static const String dragToSetCompletion   = 'Drag to set partial completion';
  static const String noSubtasksYet         = 'No subtasks yet. Tap Add to create one.';
  static const String noSubtasksMaxDepth    = 'No subtasks.';

  // ── Meta card ──────────────────────────────────────────────────────────────
  static const String metaCreated   = 'Created: ';
  static const String metaModified  = 'Modified: ';
  static const String metaDue       = 'Due: ';
  static const String metaOverdue   = ' · Overdue';
  static const String metaCompleted = 'Completed ';

  // ── Subtask tile ───────────────────────────────────────────────────────────
  static const String subtaskExpandHint = 'subtasks · Tap to expand';

  // ── Task card status labels ────────────────────────────────────────────────
  static const String statusCompleted = '✓ Completed';
  static const String statusOverdue   = '⚠ Overdue · ';
  static const String statusDue       = '📅 Due ';
  static const String statusJustNow   = 'Just now';

  // ── Dialogs ────────────────────────────────────────────────────────────────
  static const String deleteTaskTitle      = 'Delete Task?';
  static const String deleteSubtaskTitle   = 'Delete Subtask?';
  static const String deleteSubtaskSuffix  = '" and all its subtasks will be deleted.';
  static const String deleteTaskSuffix     = '" and all its subtasks will be permanently deleted.';
  static const String restoreBackupTitle   = 'Restore Backup?';
  static const String restoreBackupContent = 'This will replace ALL current tasks. Are you sure?';
  static const String btnRestore           = 'Restore';

  // ── Subtask progress labels ────────────────────────────────────────────────
  static const String subtaskCompleted      = 'Completed';
  static const String subtaskPercentSuffix  = '% complete';
  static const String subtaskOf            = ' of ';
  static const String subtaskCompletedSuffix = ' completed';
}
