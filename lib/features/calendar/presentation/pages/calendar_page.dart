import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../widgets/day_view.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';

enum CalendarViewType { day, week, month }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarViewType _viewType = CalendarViewType.week;
  DateTime _selectedDate = DateTime.now();
  List<TaskEntity> _friendTasks = [];
  String _ownColor = '#4A6741';
  final Map<String, String> _friendColors = {};
  DateTime _lastColorLoad = DateTime(2000);
  bool _isLoadingColors = false;
  StreamSubscription<dynamic>? _profileSub;
  StreamSubscription<dynamic>? _friendshipAsRequesterSub;
  StreamSubscription<dynamic>? _friendshipAsAddresseeSub;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _listenForColorChanges();
    _loadCalendarFriends();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _friendshipAsRequesterSub?.cancel();
    _friendshipAsAddresseeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReloadColors());

    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + month name + view toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing16,
                AppSpacing.spacing8,
                AppSpacing.spacing16,
                0,
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/app_icon.svg',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  // Back arrow + month/year
                  GestureDetector(
                    onTap: _goBack,
                    child: Icon(
                      Icons.chevron_left,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing4),
                  GestureDetector(
                    onTap: () => setState(
                      () => _viewType = CalendarViewType.month,
                    ),
                    child: Text(
                      _headerTitle(),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goForward,
                    child: Icon(
                      Icons.chevron_right,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // View type chips
                  _ViewChip(
                    label: 'D',
                    isSelected: _viewType == CalendarViewType.day,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.day),
                  ),
                  const SizedBox(width: 6),
                  _ViewChip(
                    label: 'W',
                    isSelected: _viewType == CalendarViewType.week,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.week),
                  ),
                  const SizedBox(width: 6),
                  _ViewChip(
                    label: 'M',
                    isSelected: _viewType == CalendarViewType.month,
                    onTap: () =>
                        setState(() => _viewType = CalendarViewType.month),
                  ),
                ],
              ),
            ),

            // Week strip header (day/week views)
            if (_viewType != CalendarViewType.month)
              _buildWeekStrip(context),

            // Calendar content
            Expanded(
              child: BlocBuilder<TasksBloc, TasksState>(
                builder: (context, state) {
                  final myTasks = _coloredTasks(state.tasks);
                  final taskMap = <String, TaskEntity>{};
                  for (final task in myTasks) {
                    taskMap[task.id] = task;
                  }
                  for (final task in _friendTasks) {
                    taskMap.putIfAbsent(task.id, () => task);
                  }
                  final tasks = taskMap.values.toList();

                  switch (_viewType) {
                    case CalendarViewType.day:
                      return DayView(
                        date: _selectedDate,
                        tasks: _tasksForDate(tasks, _selectedDate),
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.week:
                      return WeekView(
                        selectedDate: _selectedDate,
                        tasks: tasks,
                        onDateTap: (date) => setState(() {
                          _selectedDate = date;
                          _viewType = CalendarViewType.day;
                        }),
                        onTaskTap: _onTaskTap,
                      );
                    case CalendarViewType.month:
                      return MonthView(
                        month: _selectedDate,
                        tasks: tasks,
                        selectedDate: _selectedDate,
                        onDateTap: (date) => setState(() {
                          _selectedDate = date;
                          _viewType = CalendarViewType.day;
                        }),
                      );
                  }
                },
              ),
            ),

            // Bottom bar: Today button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing16,
                vertical: AppSpacing.spacing8,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing16,
                        vertical: AppSpacing.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Today',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_viewType != CalendarViewType.month)
                    Text(
                      _nextMonthLabel(),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final weekStart = _startOfWeek(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final isToday = _isSameDay(date, now);
          final isSelected = _isSameDay(date, _selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabels[date.weekday % 7],
                    style: context.textTheme.labelSmall?.copyWith(
                      color: isToday ? colors.accent : colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? (isToday ? colors.accent : colors.surfaceSubtle)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? (isToday
                                  ? Colors.white
                                  : colors.textPrimary)
                              : (isToday
                                  ? colors.accent
                                  : colors.textPrimary),
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _headerTitle() {
    switch (_viewType) {
      case CalendarViewType.month:
        return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
      case CalendarViewType.day:
      case CalendarViewType.week:
        final now = DateTime.now();
        if (_selectedDate.year == now.year) {
          return _monthNames[_selectedDate.month - 1];
        }
        return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
    }
  }

  String _nextMonthLabel() {
    final weekStart = _startOfWeek(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month != weekEnd.month) {
      return _monthNames[weekEnd.month - 1].substring(0, 3);
    }
    return '';
  }

  void _goToToday() => setState(() => _selectedDate = DateTime.now());

  void _goBack() {
    setState(() {
      switch (_viewType) {
        case CalendarViewType.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        case CalendarViewType.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month - 1,
            1,
          );
      }
    });
  }

  void _goForward() {
    setState(() {
      switch (_viewType) {
        case CalendarViewType.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
        case CalendarViewType.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            1,
          );
      }
    });
  }

  DateTime _startOfWeek(DateTime date) {
    // Sunday = 0 based
    final offset = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - offset);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TaskEntity> _tasksForDate(List<TaskEntity> tasks, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return tasks.where((t) {
      final start = t.startDate ?? t.dueDate ?? t.createdAt;
      final end = t.dueDate ?? start;
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  List<TaskEntity> _coloredTasks(List<TaskEntity> tasks) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return tasks.map((task) {
      final hex = task.ownerId == currentUserId
          ? _ownColor
          : (_friendColors[task.ownerId] ?? '#6B8FA3');
      if (hex == task.color) {
        return task;
      }
      return task.copyWith(color: hex);
    }).toList();
  }

  void _listenForColorChanges() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _profileSub?.cancel();
    _profileSub = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((_) => _loadCalendarFriends());

    _friendshipAsRequesterSub?.cancel();
    _friendshipAsRequesterSub = Supabase.instance.client
        .from('friendships')
        .stream(primaryKey: ['requester_id', 'addressee_id'])
        .eq('requester_id', userId)
        .listen((_) => _loadCalendarFriends());

    _friendshipAsAddresseeSub?.cancel();
    _friendshipAsAddresseeSub = Supabase.instance.client
        .from('friendships')
        .stream(primaryKey: ['requester_id', 'addressee_id'])
        .eq('addressee_id', userId)
        .listen((_) => _loadCalendarFriends());
  }

  void _maybeReloadColors() {
    if (!mounted || _isLoadingColors) return;
    if (DateTime.now().difference(_lastColorLoad) <
        const Duration(seconds: 2)) {
      return;
    }
    _loadCalendarFriends();
  }

  Future<void> _loadCalendarFriends() async {
    if (!mounted) return;
    _isLoadingColors = true;
    _lastColorLoad = DateTime.now();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('color')
          .eq('id', userId)
          .single();

      final friendships = await Supabase.instance.client
          .from('friendships')
          .select(
              'requester_id, addressee_id, requester_color, addressee_color')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      final friendshipRows = friendships.cast<Map<String, dynamic>>();

      final ownColor = profileData['color'] as String? ?? '#4A6741';
      final friendColors = <String, String>{};
      for (final f in friendshipRows) {
        final isRequester = f['requester_id'] == userId;
        final friendId = isRequester
            ? f['addressee_id'] as String
            : f['requester_id'] as String;
        final color = isRequester
            ? (f['requester_color'] as String? ?? '#6B8FA3')
            : (f['addressee_color'] as String? ?? '#6B8FA3');
        friendColors[friendId] = color;
      }

      setState(() {
        _ownColor = ownColor;
        _friendColors
          ..clear()
          ..addAll(friendColors);
      });

      final friendTasks = await Supabase.instance.client
          .rpc<List<dynamic>>('get_public_friend_tasks');

      final friendTaskRows = friendTasks.cast<Map<String, dynamic>>();
      final parsedFriendTasks = friendTaskRows
          .map((json) =>
              _taskFromJson(json, friendColors[json['owner_id'] as String?]))
          .toList();

      setState(() => _friendTasks = parsedFriendTasks);
    } catch (_) {
      // friend calendar tasks are optional
    } finally {
      _isLoadingColors = false;
    }
  }

  TaskEntity _taskFromJson(Map<String, dynamic> json, String? color) {
    final isPrivate =
        (json['calendar_visibility'] as String? ?? 'public') == 'private';
    return TaskEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: isPrivate ? 'Busy' : json['title'] as String,
      description: isPrivate ? null : json['description'] as String?,
      priority: _parsePriority(json['priority'] as String? ?? 'medium'),
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String).toLocal()
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      color: color,
    );
  }

  TaskPriority _parsePriority(String value) {
    switch (value) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  TaskStatus _parseStatus(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  void _onTaskTap(TaskEntity task) {
    if (task.ownerId != Supabase.instance.client.auth.currentUser?.id) {
      return;
    }
    context.read<TasksBloc>().add(TaskStatusToggled(task.id));
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
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
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? colors.accent : colors.surfaceSubtle,
        ),
        child: Center(
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isSelected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
