import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../bloc/tasks_bloc.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      buildWhen: (previous, current) => previous.filter != current.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TasksFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.spacing8),
                child: _FilterChip(
                  label: _filterLabel(filter),
                  isSelected: state.filter == filter,
                  onTap: () => context
                      .read<TasksBloc>()
                      .add(TasksFilterChanged(filter)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _filterLabel(TasksFilter filter) {
    switch (filter) {
      case TasksFilter.all:
        return 'All';
      case TasksFilter.urgent:
        return 'Urgent';
      case TasksFilter.high:
        return 'High';
      case TasksFilter.medium:
        return 'Medium';
      case TasksFilter.low:
        return 'Low';
      case TasksFilter.completed:
        return 'Done';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
