// Task creation / edit form sheet — supports gallery, camera and URL image input.
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/task.dart';

class TaskFormSheet extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialImagePath;
  final String? initialImageUrl;
  final DateTime? initialDueDate;
  final TaskPriority initialPriority;

  /// 6-param callback: title, description, imagePath, imageUrl, dueDate, priority
  final void Function(
    String title,
    String? description,
    String? imagePath,
    String? imageUrl,
    DateTime? dueDate,
    TaskPriority priority,
  ) onSubmit;

  const TaskFormSheet({
    super.key,
    this.title = 'New Task',
    this.initialTitle,
    this.initialDescription,
    this.initialImagePath,
    this.initialImageUrl,
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
  late final TextEditingController _urlCtrl;
  final _formKey = GlobalKey<FormState>();

  String? _imagePath;
  String? _pendingImageUrl;
  DateTime? _dueDate;
  late TaskPriority _priority;
  bool _pickingImage = false;
  bool _downloadingUrl = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descCtrl = TextEditingController(text: widget.initialDescription);
    _urlCtrl = TextEditingController(text: widget.initialImageUrl ?? '');
    _imagePath = widget.initialImagePath;
    _pendingImageUrl = widget.initialImageUrl;
    _dueDate = widget.initialDueDate;
    _priority = widget.initialPriority;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
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
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
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
                    _buildSectionLabel(context, AppStrings.labelThumbnail),
                    const Gap(8),
                    _ImagePickerArea(
                      imagePath: _imagePath,
                      pendingImageUrl: _pendingImageUrl,
                      loading: _pickingImage,
                      onPick: _pickImage,
                      onRemove: () => setState(() {
                        _imagePath = null;
                        _pendingImageUrl = null;
                        _urlCtrl.clear();
                      }),
                    ),
                    const Gap(12),

                    // ── Image URL ─────────────────────────────────
                    _buildSectionLabel(context, AppStrings.labelImageUrl),
                    const Gap(8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _urlCtrl,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              hintText: AppStrings.hintImageUrl,
                              suffixIcon: _urlCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _urlCtrl.clear();
                                        setState(() => _pendingImageUrl = null);
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const Gap(8),
                        SizedBox(
                          height: 48,
                          child: _downloadingUrl
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : FilledButton.tonal(
                                  onPressed: _urlCtrl.text.trim().isEmpty
                                      ? null
                                      : _applyUrl,
                                  child: const Text(AppStrings.btnUse),
                                ),
                        ),
                      ],
                    ),
                    if (_pendingImageUrl != null) ...[
                      const Gap(6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              'URL set: $_pendingImageUrl',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Gap(20),

                    // ── Title ─────────────────────────────────────
                    _buildSectionLabel(context, AppStrings.labelTaskTitle),
                    const Gap(8),
                    TextFormField(
                      controller: _titleCtrl,
                      autofocus: widget.initialTitle == null,
                      decoration: const InputDecoration(hintText: AppStrings.hintTaskTitle),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.validationTitleEmpty
                          : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Gap(16),

                    // ── Description ───────────────────────────────
                    _buildSectionLabel(context, AppStrings.labelDescription),
                    const Gap(8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: AppStrings.hintDescription,
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Gap(16),

                    // ── Due Date ──────────────────────────────────
                    _buildSectionLabel(context, AppStrings.labelDueDate),
                    const Gap(8),
                    _DueDatePicker(
                      dueDate: _dueDate,
                      onChanged: (d) => setState(() => _dueDate = d),
                    ),
                    const Gap(16),

                    // ── Priority ──────────────────────────────────
                    _buildSectionLabel(context, AppStrings.labelPriority),
                    const Gap(8),
                    _PrioritySelector(
                      selected: _priority,
                      onChanged: (pr) => setState(() => _priority = pr),
                    ),
                    const Gap(28),

                    // ── Actions ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(AppStrings.btnCancel),
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
                                    ? AppStrings.btnSaveChanges
                                    : AppStrings.btnSaveTask,
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
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
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
        xfile.path,
        destPath,
        minWidth: 250,
        minHeight: 250,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        setState(() {
          _imagePath = result.path;
          _pendingImageUrl = null; // file takes priority
          _urlCtrl.clear();
        });
      }
    } finally {
      setState(() => _pickingImage = false);
    }
  }

  Future<void> _applyUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.imageUrlInvalid)),
        );
      }
      return;
    }

    setState(() => _downloadingUrl = true);
    try {
      final client = HttpClient();
      final req = await client
          .headUrl(uri)
          .timeout(const Duration(seconds: 8));
      final resp = await req.close();
      client.close();

      if (resp.statusCode >= 200 && resp.statusCode < 400) {
        setState(() {
          _pendingImageUrl = url;
          _imagePath = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.imageUrlSetting),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.imageUrlUnreachable}${resp.statusCode})'),
            ),
          );
        }
      }
    } catch (_) {
      // Accept anyway — server might reject HEAD but serve GET fine
      setState(() {
        _pendingImageUrl = url;
        _imagePath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppStrings.imageUrlSaved),
            ),
        );
      }
    } finally {
      setState(() => _downloadingUrl = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      _imagePath,
      _pendingImageUrl,
      _dueDate,
      _priority,
    );
    Navigator.of(context).pop();
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ImagePickerArea extends StatelessWidget {
  final String? imagePath;
  final String? pendingImageUrl;
  final bool loading;
  final void Function({bool fromCamera}) onPick;
  final VoidCallback onRemove;

  const _ImagePickerArea({
    required this.imagePath,
    this.pendingImageUrl,
    required this.loading,
    required this.onPick,
    required this.onRemove,
  });

  bool get _hasContent => imagePath != null || pendingImageUrl != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _hasContent ? null : () => _showOptions(context),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : _hasContent
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: pendingImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_outlined,
                                          size: 32,
                                          color: theme.colorScheme.onSurfaceVariant),
                                      const Gap(4),
                                      Text('URL preview unavailable',
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                              ),
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
                      // Tap-to-change overlay
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: GestureDetector(
                          onTap: () => _showOptions(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(AppStrings.btnChange,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 36, color: theme.colorScheme.onSurfaceVariant),
                      const Gap(8),
                        Text(
                        AppStrings.tapToSelect,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
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
              title: const Text(AppStrings.imagePickGallery),
              onTap: () {
                Navigator.pop(context);
                onPick(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text(AppStrings.imagePickCamera),
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                      : AppStrings.hintDueDate,
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

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((pr) {
        final isSelected = pr == selected;
        final color = switch (pr) {
          TaskPriority.high => Colors.red.shade400,
          TaskPriority.medium => Colors.orange.shade400,
          TaskPriority.low => Colors.green.shade400,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(pr),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? color : color.withValues(alpha: 0.5),
                      size: 22,
                    ),
                    const Gap(4),
                    Text(
                      pr.label,
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





