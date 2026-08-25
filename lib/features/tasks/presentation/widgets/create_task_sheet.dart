import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/tasks_bloc.dart';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _startDate;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),

            // Title
            Text('New Task', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.spacing20),

            // Task title input
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Description input
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Add details (optional)',
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: AppSpacing.spacing20),

            // Priority selector
            Text('Priority', style: context.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.spacing8),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _priority == priority;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: priority != TaskPriority.low
                          ? AppSpacing.spacing8
                          : 0,
                    ),
                    child: _PriorityOption(
                      priority: priority,
                      isSelected: isSelected,
                      onTap: () => setState(() => _priority = priority),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.spacing20),

            // Start date
            GestureDetector(
              onTap: _pickStartDate,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: Text(
                        _startDate != null
                            ? 'Start: ${_formatDateTime(_startDate!)}'
                            : 'Set start date & time (optional)',
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _startDate = null),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),

            // Due date
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: Text(
                        _dueDate != null
                            ? 'End: ${_formatDateTime(_dueDate!)}'
                            : 'Set end date & time (optional)',
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),

            // Create button
            ElevatedButton(
              onPressed: _createTask,
              child: const Text('Create Task'),
            ),
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _startDate ?? DateTime.now(),
      ),
    );
    if (!mounted) return;

    final time = pickedTime ?? TimeOfDay.fromDateTime(DateTime.now());
    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _dueDate ?? _startDate?.add(const Duration(hours: 1)) ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _dueDate ?? _startDate?.add(const Duration(hours: 1)) ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (!mounted) return;

    final time = pickedTime ?? const TimeOfDay(hour: 23, minute: 59);
    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute $period';
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    context.read<TasksBloc>().add(
          TaskCreateRequested(
            title: title,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            priority: _priority,
            startDate: _startDate,
            dueDate: _dueDate,
          ),
        );

    Navigator.of(context).pop();
  }
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final priorityColor = _getColor(colors);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? priorityColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isSelected ? priorityColor : colors.border,
          ),
        ),
        child: Center(
          child: Text(
            _label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected ? priorityColor : colors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String get _label {
    switch (priority) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _getColor(AppColorScheme colors) {
    switch (priority) {
      case TaskPriority.urgent:
        return colors.urgent;
      case TaskPriority.high:
        return colors.high;
      case TaskPriority.medium:
        return colors.medium;
      case TaskPriority.low:
        return colors.low;
    }
  }
}
