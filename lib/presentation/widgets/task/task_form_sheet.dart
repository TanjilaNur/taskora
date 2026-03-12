import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../domain/entities/task.dart';

class TaskFormSheet extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialImagePath;
  final DateTime? initialDueDate;
  final TaskPriority initialPriority;
  final void Function(String title, String? description, String? imagePath,
      DateTime? dueDate, TaskPriority priority) onSubmit;

  const TaskFormSheet({
    super.key,
    this.title = 'New Task',
    this.initialTitle,
    this.initialDescription,
    this.initialImagePath,
    this.initialDueDate,
    this.initialPriority = TaskPriority.medium,
    required this.onSubmit,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();

  String? _imagePath;
  DateTime? _dueDate;
  late TaskPriority _priority;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descCtrl = TextEditingController(text: widget.initialDescription);
    _imagePath = widget.initialImagePath;
    _dueDate = widget.initialDueDate;
    _priority = widget.initialPriority;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Single drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                  children: [
                    const Gap(10),
                    Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Gap(20),

                    // ── Image Upload ──────────────────────────────
                    _buildSectionLabel(context, '📷 Upload Thumbnail (250x250px)'),
                    const Gap(8),
                    _ImagePickerArea(
                      imagePath: _imagePath,
                      loading: _pickingImage,
                      onPick: _pickImage,
                      onRemove: () => setState(() => _imagePath = null),
                    ),
                    const Gap(20),

                    // ── Title ─────────────────────────────────────
                    _buildSectionLabel(context, '📝 Task Title *'),
                    const Gap(8),
                    TextFormField(
                      controller: _titleCtrl,
                      autofocus: widget.initialTitle == null,
                      decoration: const InputDecoration(
                          hintText: 'Enter task title'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Gap(16),

                    // ── Description ───────────────────────────────
                    _buildSectionLabel(context, '📄 Description'),
                    const Gap(8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Add a description (optional)',
                          alignLabelWithHint: true),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Gap(16),

                    // ── Due Date ──────────────────────────────────
                    _buildSectionLabel(context, '📅 Due Date (Optional)'),
                    const Gap(8),
                    _DueDatePicker(
                      dueDate: _dueDate,
                      onChanged: (d) => setState(() => _dueDate = d),
                    ),
                    const Gap(16),

                    // ── Priority ──────────────────────────────────
                    _buildSectionLabel(context, '🎯 Priority'),
                    const Gap(8),
                    _PrioritySelector(
                      selected: _priority,
                      onChanged: (p) => setState(() => _priority = p),
                    ),
                    const Gap(28),

                    // ── Actions ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                widget.initialTitle != null
                                    ? 'Save Changes'
                                    : 'Save Task',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600));
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    setState(() => _pickingImage = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery);
      if (xfile == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'task_images'));
      if (!imagesDir.existsSync()) await imagesDir.create(recursive: true);

      final destPath = p.join(imagesDir.path, '${const Uuid().v4()}.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        xfile.path, destPath,
        minWidth: 250, minHeight: 250,
        quality: 85, format: CompressFormat.jpeg,
      );
      if (result != null) setState(() => _imagePath = result.path);
    } finally {
      setState(() => _pickingImage = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      _imagePath,
      _dueDate,
      _priority,
    );
    Navigator.of(context).pop();
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ImagePickerArea extends StatelessWidget {
  final String? imagePath;
  final bool loading;
  final void Function({bool fromCamera}) onPick;
  final VoidCallback onRemove;

  const _ImagePickerArea({
    required this.imagePath,
    required this.loading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              style: BorderStyle.solid),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : imagePath != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant),
            const Gap(8),
            Text('Tap to select or take a photo',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onPick(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                onPick(fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;

  const _DueDatePicker({required this.dueDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const Gap(10),
            Expanded(
              child: Text(
                dueDate != null
                    ? DateFormat('MMM d, yyyy').format(dueDate!)
                    : 'Select a due date',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dueDate != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (dueDate != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
              )
            else
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = p == selected;
        final color = switch (p) {
          TaskPriority.high => Colors.red.shade400,
          TaskPriority.medium => Colors.orange.shade400,
          TaskPriority.low => Colors.green.shade400,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                  isSelected ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Radio<TaskPriority>(
                      value: p,
                      groupValue: selected,
                      onChanged: (v) => onChanged(v!),
                      activeColor: color,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}