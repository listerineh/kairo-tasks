import 'dart:async';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/session/current_user.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_avatar.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../../core/widgets/kairo_sheet.dart';
import '../../../social/domain/entities/friend.dart';
import '../../../social/domain/usecases/get_friends.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/quick_dates.dart';
import '../bloc/tasks_bloc.dart';

/// Opens the task form: a new task, or [task] to edit it.
///
/// [initialFriendId] pre-selects a friend to share a new task with (from
/// the Social tab). [initialStart] pre-fills a new task's date and a
/// 30 minute slot (from tapping an empty calendar slot).
Future<void> showTaskForm(
  BuildContext context, {
  TaskEntity? task,
  String? initialFriendId,
  DateTime? initialStart,
}) {
  final bloc = context.read<TasksBloc>();
  return showKairoSheet<void>(
    context: context,
    detents: const [KairoSheetDetent.large],
    builder: (context, controller) => BlocProvider.value(
      value: bloc,
      child: TaskFormSheet(
        task: task,
        initialFriendId: initialFriendId,
        initialStart: initialStart,
        scrollController: controller,
      ),
    ),
  );
}

/// One form for creating and editing tasks (docs/redesign-plan.md §3).
///
/// Title first: Return saves. Date, priority and sharing stay folded behind
/// small buttons until needed (or shown when the task already uses them).
/// Dates come from Today / Tomorrow / This weekend chips or a picker; a
/// time, and then a start time, are optional.
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    this.task,
    this.initialFriendId,
    this.initialStart,
    this.scrollController,
    this.loadFriends,
    this.currentUserId,
    this.now,
    super.key,
  });

  final TaskEntity? task;
  final String? initialFriendId;

  /// Start of a new task's time slot; ignored when editing.
  final DateTime? initialStart;
  final ScrollController? scrollController;

  /// Defaults to the registered [GetFriends] use case.
  final Future<Either<Failure, List<Friend>>> Function()? loadFriends;

  /// Defaults to the signed-in user; decides who may change sharing.
  final String? currentUserId;

  /// Reference time for the date chips (tests).
  final DateTime? now;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late TaskPriority _priority;
  DateTime? _day;
  TimeOfDay? _time;
  TimeOfDay? _start;

  /// A start date the form cannot express (another day than the due date);
  /// kept as is unless the date is changed or removed.
  DateTime? _keptStart;
  late final Set<String> _shared;

  late bool _showDate;
  late bool _showPriority;
  late bool _showShare;

  List<Friend> _friends = const [];

  bool get _editing => widget.task != null;
  DateTime get _now => widget.now ?? DateTime.now();

  bool get _canShare {
    final task = widget.task;
    if (task == null) return true;
    final me =
        widget.currentUserId ??
        (getIt.isRegistered<CurrentUser>() ? getIt<CurrentUser>().id : null);
    return task.ownerId == me;
  }

  bool get _valid => _title.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '')
      ..addListener(() => setState(() {}));
    _notes = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _shared = {
      for (final p in task?.sharedWith ?? const <Map<String, dynamic>>[])
        if (p['id'] case final String id) id,
      if (widget.initialFriendId case final id?) id,
    };
    _initDates(task);

    _showDate = _day != null;
    _showPriority = _priority != TaskPriority.medium;
    _showShare = _shared.isNotEmpty;
    unawaited(_fetchFriends());
  }

  void _initDates(TaskEntity? task) {
    final slot = task == null ? widget.initialStart : null;
    if (slot != null) {
      _day = DateTime(slot.year, slot.month, slot.day);
      _start = TimeOfDay.fromDateTime(slot);
      final end = slot.add(const Duration(minutes: 30));
      // A slot at the end of the day ends at 23:59, not tomorrow.
      _time = DateUtils.isSameDay(end, slot)
          ? TimeOfDay.fromDateTime(end)
          : const TimeOfDay(hour: 23, minute: 59);
      return;
    }
    final due = task?.dueDate;
    final start = task?.startDate;
    final date = due ?? start;
    if (date == null) return;
    _day = DateTime(date.year, date.month, date.day);
    if (hasTimeOfDay(date)) _time = TimeOfDay.fromDateTime(date);
    if (due != null && start != null) {
      if (DateUtils.isSameDay(start, due) && hasTimeOfDay(start)) {
        _start = TimeOfDay.fromDateTime(start);
      } else {
        _keptStart = start;
      }
    }
  }

  Future<void> _fetchFriends() async {
    final load =
        widget.loadFriends ??
        (getIt.isRegistered<GetFriends>() ? getIt<GetFriends>().call : null);
    if (load == null) return;
    final result = await load();
    if (!mounted) return;
    // Sharing is optional: without friends the option simply stays hidden.
    result.fold((_) {}, (friends) => setState(() => _friends = friends));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  TaskDraft _draft() {
    final day = _day;
    DateTime? due;
    DateTime? start;
    if (day != null) {
      due = withTime(day, _time == null ? null : _hm(_time!));
      start = _start != null && _time != null
          ? withTime(day, _hm(_start!))
          : _keptStart;
    }
    final notes = _notes.text.trim();
    return TaskDraft(
      title: _title.text.trim(),
      description: notes.isEmpty ? null : notes,
      priority: _priority,
      startDate: start,
      dueDate: due,
      sharedWithIds: _canShare ? _shared.toList() : null,
    );
  }

  static ({int hour, int minute}) _hm(TimeOfDay t) =>
      (hour: t.hour, minute: t.minute);

  void _save() {
    if (!_valid) return;
    final draft = _draft();
    final bloc = context.read<TasksBloc>();
    final task = widget.task;
    if (task == null) {
      bloc.add(
        TaskCreateRequested(
          title: draft.title,
          description: draft.description,
          priority: draft.priority,
          startDate: draft.startDate,
          dueDate: draft.dueDate,
          sharedWith: draft.sharedWithIds,
        ),
      );
    } else {
      bloc.add(TaskEdited(task.id, draft));
    }
    Navigator.of(context).pop();
  }

  void _setDay(DateTime? day) => setState(() {
    _day = day;
    // A start on another day no longer makes sense once the date moves.
    _keptStart = null;
    if (day == null) {
      _time = null;
      _start = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      children: [
        _Header(
          title: _editing ? l10n.editTask : l10n.newTask,
          saveLabel: _editing ? l10n.taskFormSave : l10n.taskFormAdd,
          canSave: _valid,
          onCancel: () => Navigator.of(context).pop(),
          onSave: _save,
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.only(
              top: AppSpacing.spacing8,
              bottom: bottom + 32,
            ),
            children: [
              _textSection(context),
              if (_showDate) _gap(_dateSection(context)),
              if (_showPriority) _gap(_prioritySection(context)),
              if (_showShare && _canShare && _friends.isNotEmpty)
                _gap(_shareSection(context)),
              _gap(_revealButtons(context)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _gap(Widget child) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.spacing24),
    child: child,
  );

  Widget _textSection(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    InputDecoration plain(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.labelTertiary),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: 12,
      ),
    );

    return GroupedSection(
      children: [
        TextField(
          controller: _title,
          autofocus: !_editing,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: type.body.copyWith(color: colors.label),
          decoration: plain(context.l10n.titleHint),
        ),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: type.subheadline.copyWith(color: colors.label),
          decoration: plain(context.l10n.descriptionHint),
        ),
      ],
    );
  }

  Widget _dateSection(BuildContext context) {
    final l10n = context.l10n;
    final selected = matchingQuickDate(_day, _now);
    final custom = _day != null && selected == null;

    return GroupedSection(
      header: l10n.taskFormDate,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          child: Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: [
              for (final (q, label) in [
                (QuickDate.today, l10n.today),
                (QuickDate.tomorrow, l10n.tomorrow),
                (QuickDate.weekend, l10n.taskFormThisWeekend),
              ])
                _Chip(
                  label: label,
                  selected: selected == q,
                  onTap: () => _setDay(quickDate(q, _now)),
                ),
              _Chip(
                label: custom
                    ? MaterialLocalizations.of(context).formatMediumDate(_day!)
                    : l10n.taskFormPickDate,
                icon: CupertinoIcons.calendar,
                selected: custom,
                onTap: _pickDay,
              ),
            ],
          ),
        ),
        if (_day != null) ...[
          GroupedRow(
            leading: const Icon(CupertinoIcons.clock),
            title: l10n.taskFormTime,
            trailing: Text(_time == null ? l10n.taskFormAdd : _format(_time!)),
            onTap: () => _pickTime(start: false),
          ),
          if (_time != null)
            GroupedRow(
              leading: const Icon(CupertinoIcons.play),
              title: l10n.taskFormStarts,
              trailing: Text(
                _start == null ? l10n.taskFormAdd : _format(_start!),
              ),
              onTap: () => _pickTime(start: true),
            ),
          GroupedRow(
            title: l10n.taskFormRemoveDate,
            destructive: true,
            onTap: () => _setDay(null),
          ),
        ],
      ],
    );
  }

  Widget _prioritySection(BuildContext context) {
    final l10n = context.l10n;
    return GroupedSection(
      header: l10n.priority,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
          child: KairoSegmentedControl<TaskPriority>(
            segments: {
              TaskPriority.low: l10n.low,
              TaskPriority.medium: l10n.medium,
              TaskPriority.high: l10n.high,
              TaskPriority.urgent: l10n.urgent,
            },
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
        ),
      ],
    );
  }

  Widget _shareSection(BuildContext context) {
    final colors = context.appColors;
    return GroupedSection(
      header: context.l10n.shareWith,
      children: [
        for (final friend in _friends)
          Semantics(
            selected: _shared.contains(friend.id),
            child: GroupedRow(
              leading: KairoAvatar(
                name: friend.displayName ?? friend.username ?? '',
                imageUrl: friend.avatarUrl,
                size: 28,
              ),
              title: friend.name.isEmpty ? context.l10n.friend : friend.name,
              trailing: _shared.contains(friend.id)
                  ? Icon(CupertinoIcons.checkmark, color: colors.tint, size: 20)
                  : null,
              onTap: () => setState(
                () => _shared.contains(friend.id)
                    ? _shared.remove(friend.id)
                    : _shared.add(friend.id),
              ),
            ),
          ),
      ],
    );
  }

  /// Buttons that unfold the optional sections still hidden.
  Widget _revealButtons(BuildContext context) {
    final l10n = context.l10n;
    final buttons = [
      if (!_showDate)
        _Chip(
          label: l10n.taskFormDate,
          icon: CupertinoIcons.calendar,
          onTap: () => setState(() {
            _showDate = true;
            _day ??= quickDate(QuickDate.today, _now);
          }),
        ),
      if (!_showPriority)
        _Chip(
          label: l10n.priority,
          icon: CupertinoIcons.flag,
          onTap: () => setState(() => _showPriority = true),
        ),
      if (!_showShare && _canShare && _friends.isNotEmpty)
        _Chip(
          label: l10n.shareWith,
          icon: CupertinoIcons.person_2,
          onTap: () => setState(() => _showShare = true),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Wrap(
        spacing: AppSpacing.spacing8,
        runSpacing: AppSpacing.spacing8,
        children: buttons,
      ),
    );
  }

  String _format(TimeOfDay t) => MaterialLocalizations.of(context)
      .formatTimeOfDay(
        t,
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  Future<void> _pickDay() async {
    final picked = await _cupertinoPicker(
      mode: CupertinoDatePickerMode.date,
      initial: _day ?? _now,
    );
    if (picked != null) {
      _setDay(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final day = _day!;
    final current = start ? (_start ?? _time) : _time;
    final initial = current == null
        ? DateTime(day.year, day.month, day.day, 9)
        : withTime(day, _hm(current));
    final picked = await _cupertinoPicker(
      mode: CupertinoDatePickerMode.time,
      initial: initial,
    );
    if (picked == null) return;
    final time = TimeOfDay.fromDateTime(picked);
    setState(() {
      if (start) {
        _start = time;
        // Keep start before due: push the due time 30 minutes past it.
        if (_toMinutes(time) >= _toMinutes(_time!)) {
          final end = _toMinutes(time) + 30;
          _time = end < 24 * 60
              ? TimeOfDay(hour: end ~/ 60, minute: end % 60)
              : const TimeOfDay(hour: 23, minute: 59);
        }
      } else {
        _time = time;
        if (_start != null && _toMinutes(_start!) >= _toMinutes(time)) {
          _start = null;
        }
      }
    });
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<DateTime?> _cupertinoPicker({
    required CupertinoDatePickerMode mode,
    required DateTime initial,
  }) {
    var value = initial;
    final colors = context.appColors;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (popup) => Container(
        height: 300,
        color: colors.surfaceRaised,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.of(popup).pop(value),
                  child: Text(
                    context.l10n.taskFormDone,
                    style: TextStyle(
                      color: colors.tint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: initial,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                  onDateTimeChanged: (v) => value = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet bar: Cancel · title · Add/Save (disabled until there is a title).
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.saveLabel,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final String saveLabel;
  final bool canSave;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Row(
        children: [
          CupertinoButton(
            onPressed: onCancel,
            child: Text(
              context.l10n.cancel,
              style: type.body.copyWith(color: colors.tint),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.headline.copyWith(color: colors.label),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: canSave ? onSave : null,
            child: Text(
              saveLabel,
              style: type.headline.copyWith(
                color: canSave ? colors.tint : colors.labelTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Capsule chip for date shortcuts and the "show more" buttons.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = selected ? colors.tint : colors.label;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? colors.tintSoft : colors.fill,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: context.typography.subheadline.copyWith(
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
