import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/timeline_layout.dart';
import 'calendar_colors.dart';

/// Hour grid for one or more days (Day = 1 column, Week = 2).
///
/// - Pinch with two fingers to change the hour height.
/// - Tap an empty slot to create a task there (snapped to 15 min).
/// - Long-press a block you own and drag it: it snaps to 15 minutes with a
///   haptic tick, and can move to a neighbouring day column.
class TimeGrid extends StatefulWidget {
  const TimeGrid({
    required this.days,
    required this.tasks,
    required this.onTaskTap,
    required this.onCreateAt,
    required this.onMove,
    required this.canMove,
    this.now,
    this.initialHourHeight = 56,
    this.bottomInset = 0,
    super.key,
  });

  final List<DateTime> days;
  final List<TaskEntity> tasks;
  final ValueChanged<TaskEntity> onTaskTap;
  final ValueChanged<DateTime> onCreateAt;

  /// The new start time for the block's start (length is kept by caller).
  final void Function(TaskEntity task, DateTime newStart) onMove;
  final bool Function(TaskEntity task) canMove;

  /// Current time, for the "now" line and the initial scroll (tests).
  final DateTime? now;
  final double initialHourHeight;

  /// Extra space below the last hour (e.g. for the tab bar).
  final double bottomInset;

  static const double minHourHeight = 32;
  static const double maxHourHeight = 140;
  static const double gutterWidth = 56;

  @override
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  late double _hourHeight = widget.initialHourHeight;
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _initialOffset(),
  );

  // Pinch tracking, outside the gesture arena so scrolling keeps working.
  final Map<int, Offset> _pointers = {};
  double? _pinchStartSpan;
  double _pinchStartHeight = 0;

  DateTime get _now => widget.now ?? DateTime.now();

  double _initialOffset() {
    // Open around the current hour, a little above it.
    final hour = (_now.hour - 1).clamp(0, 23);
    return hour * widget.initialHourHeight;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2) {
      _pinchStartSpan = _span();
      _pinchStartHeight = _hourHeight;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    final start = _pinchStartSpan;
    if (_pointers.length != 2 || start == null || start < 1) return;
    final next = (_pinchStartHeight * _span() / start).clamp(
      TimeGrid.minHourHeight,
      TimeGrid.maxHourHeight,
    );
    if ((next - _hourHeight).abs() > 0.5) setState(() => _hourHeight = next);
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchStartSpan = null;
  }

  double _span() {
    final points = _pointers.values.toList();
    return (points[0].dy - points[1].dy).abs();
  }

  @override
  Widget build(BuildContext context) {
    final hasAllDay = widget.days.any(
      (d) => allDayTasks(widget.tasks, d).isNotEmpty,
    );

    return Column(
      children: [
        if (hasAllDay)
          _AllDayStrip(
            days: widget.days,
            tasks: widget.tasks,
            onTap: widget.onTaskTap,
          ),
        Expanded(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: SingleChildScrollView(
              controller: _scroll,
              // Two fingers resize the grid; don't scroll at the same time.
              physics: _pinchStartSpan != null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              // Room for a floating tab bar under the last hour.
              padding: EdgeInsets.only(bottom: widget.bottomInset),
              child: SizedBox(
                height: _hourHeight * 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HourGutter(hourHeight: _hourHeight),
                    for (var i = 0; i < widget.days.length; i++)
                      Expanded(
                        child: _DayColumn(
                          day: widget.days[i],
                          dayIndex: i,
                          dayCount: widget.days.length,
                          blocks: layoutDay(widget.tasks, widget.days[i]),
                          hourHeight: _hourHeight,
                          now: _now,
                          onTaskTap: widget.onTaskTap,
                          onCreateAt: widget.onCreateAt,
                          canMove: widget.canMove,
                          onMove: (task, dayShift, minute) {
                            final target = widget.days[i];
                            widget.onMove(
                              task,
                              DateTime(
                                target.year,
                                target.month,
                                target.day + dayShift,
                                minute ~/ 60,
                                minute % 60,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HourGutter extends StatelessWidget {
  const _HourGutter({required this.hourHeight});

  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final style = context.typography.caption1.copyWith(
      color: context.appColors.labelSecondary,
    );
    return SizedBox(
      width: TimeGrid.gutterWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var h = 1; h < 24; h++)
            Positioned(
              top: h * hourHeight - 8,
              right: 8,
              child: ExcludeSemantics(
                child: Text(
                  _hourLabel(localizations, h, use24: use24),
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.3),
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "10 AM" or "10:00", like iOS Calendar; a full "10:00 AM" does not fit.
String _hourLabel(
  MaterialLocalizations localizations,
  int hour, {
  required bool use24,
}) {
  if (use24) {
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: hour, minute: 0),
      alwaysUse24HourFormat: true,
    );
  }
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12
      ? localizations.anteMeridiemAbbreviation
      : localizations.postMeridiemAbbreviation;
  return '$h12 $period';
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.dayIndex,
    required this.dayCount,
    required this.blocks,
    required this.hourHeight,
    required this.now,
    required this.onTaskTap,
    required this.onCreateAt,
    required this.canMove,
    required this.onMove,
  });

  final DateTime day;
  final int dayIndex;
  final int dayCount;
  final List<TimelineBlock> blocks;
  final double hourHeight;
  final DateTime now;
  final ValueChanged<TaskEntity> onTaskTap;
  final ValueChanged<DateTime> onCreateAt;
  final bool Function(TaskEntity) canMove;
  final void Function(TaskEntity task, int dayShift, int minute) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isToday = DateUtils.isSameDay(day, now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final minute = snapMinute(d.localPosition.dy / hourHeight * 60);
            onCreateAt(
              DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Hour lines and the day separator.
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    hourHeight: hourHeight,
                    line: colors.separator,
                    leftEdge: dayIndex > 0,
                  ),
                ),
              ),
              for (final b in blocks)
                _Block(
                  key: ValueKey('${b.task.id}-$dayIndex'),
                  block: b,
                  hourHeight: hourHeight,
                  columnWidth: width,
                  dayIndex: dayIndex,
                  dayCount: dayCount,
                  canMove: canMove(b.task),
                  onTap: () => onTaskTap(b.task),
                  onMove: (shift, minute) => onMove(b.task, shift, minute),
                ),
              if (isToday)
                Positioned(
                  top: (now.hour * 60 + now.minute) / 60 * hourHeight - 1,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(height: 2, color: colors.destructive),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.hourHeight,
    required this.line,
    required this.leftEdge,
  });

  final double hourHeight;
  final Color line;
  final bool leftEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = AppSpacing.hairline;
    for (var h = 1; h < 24; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    if (leftEdge) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.hourHeight != hourHeight ||
      old.line != line ||
      old.leftEdge != leftEdge;
}

/// One task block. Long press lifts it; dragging snaps to 15 minutes.
class _Block extends StatefulWidget {
  const _Block({
    required this.block,
    required this.hourHeight,
    required this.columnWidth,
    required this.dayIndex,
    required this.dayCount,
    required this.canMove,
    required this.onTap,
    required this.onMove,
    super.key,
  });

  final TimelineBlock block;
  final double hourHeight;
  final double columnWidth;
  final int dayIndex;
  final int dayCount;
  final bool canMove;
  final VoidCallback onTap;
  final void Function(int dayShift, int minute) onMove;

  @override
  State<_Block> createState() => _BlockState();
}

class _BlockState extends State<_Block> {
  bool _dragging = false;
  int? _minute;
  int _dayShift = 0;

  int get _length => widget.block.endMinute - widget.block.startMinute;

  void _start(LongPressStartDetails _) {
    final haptics = registeredHaptics;
    if (haptics != null) unawaited(haptics.selection());
    setState(() {
      _dragging = true;
      _minute = widget.block.startMinute;
      _dayShift = 0;
    });
  }

  void _update(LongPressMoveUpdateDetails d) {
    final raw =
        widget.block.startMinute +
        d.offsetFromOrigin.dy / widget.hourHeight * 60;
    final minute = snapMinute(raw).clamp(0, minutesPerDay - _length);
    final shift = (d.offsetFromOrigin.dx / widget.columnWidth).round().clamp(
      -widget.dayIndex,
      widget.dayCount - 1 - widget.dayIndex,
    );
    if (minute != _minute || shift != _dayShift) {
      final haptics = registeredHaptics;
      if (haptics != null) unawaited(haptics.selection());
      setState(() {
        _minute = minute;
        _dayShift = shift;
      });
    }
  }

  void _end(LongPressEndDetails _) {
    final minute = _minute;
    setState(() => _dragging = false);
    if (minute == null) return;
    if (minute != widget.block.startMinute || _dayShift != 0) {
      widget.onMove(_dayShift, minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final colors = context.appColors;
    final type = context.typography;
    final tone = CalendarTone.of(b.task.color);
    final brightness = Theme.of(context).brightness;
    final light = brightness == Brightness.light;
    final width = widget.columnWidth / b.columns;
    final minute = _dragging ? _minute! : b.startMinute;
    final top = minute / 60 * widget.hourHeight;
    final height = (_length / 60 * widget.hourHeight).clamp(
      18.0,
      double.infinity,
    );
    final done = b.task.status == TaskStatus.completed;
    final tall = height > 40;

    return Positioned(
      top: top,
      left: b.column * width + _dayShift * widget.columnWidth + 1,
      width: width - 2,
      height: height - 2,
      child: Semantics(
        button: true,
        label: b.task.title,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPressStart: widget.canMove ? _start : null,
          onLongPressMoveUpdate: widget.canMove ? _update : null,
          onLongPressEnd: widget.canMove ? _end : null,
          child: AnimatedScale(
            scale: _dragging ? 1.03 : 1,
            duration: const Duration(milliseconds: 120),
            child: Opacity(
              opacity: done ? 0.55 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.fillFor(brightness, colors.surface),
                  borderRadius: BorderRadius.circular(tall ? 14 : 8),
                  boxShadow: _dragging
                      ? const [
                          BoxShadow(
                            color: Color(0x33121417),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, tall ? 6 : 2, 6, 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tone.dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          b.task.title,
                          maxLines: tall ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: MediaQuery.textScalerOf(context)
                              .clamp(maxScaleFactor: 1.3),
                          style: type.footnote.copyWith(
                            color: light
                                ? const Color(0xFF121417)
                                : colors.label,
                            fontWeight: FontWeight.w700,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip({
    required this.days,
    required this.tasks,
    required this.onTap,
  });

  final List<DateTime> days;
  final List<TaskEntity> tasks;
  final ValueChanged<TaskEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.separator,
            width: AppSpacing.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: TimeGrid.gutterWidth),
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final t in allDayTasks(tasks, day))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: _AllDayChip(task: t, onTap: () => onTap(t)),
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
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.task, required this.onTap});

  final TaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = CalendarTone.of(task.color);
    final brightness = Theme.of(context).brightness;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tone.fillFor(brightness, colors.surface),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.caption1.copyWith(
                color: brightness == Brightness.light
                    ? const Color(0xFF121417)
                    : colors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
