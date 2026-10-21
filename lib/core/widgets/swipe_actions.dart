import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../../app/theme/app_motion.dart';
import '../extensions/context_extensions.dart';
import '../services/haptics_service.dart';

class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTriggered,
    this.foreground,
  });

  final IconData icon;

  /// Shown under the icon and used as the accessibility action name.
  final String label;
  final Color color;

  /// Icon and label color; defaults to the theme's on-tint color.
  final Color? foreground;
  final VoidCallback onTriggered;
}

/// Mail-style swipe actions (docs/redesign-plan.md §3, Tasks).
///
/// Dragging reveals [leading] (swipe right) or [trailing] (swipe left)
/// buttons. Releasing past half the buttons' width snaps open; swiping past
/// [fullSwipeFraction] of the row commits the outermost action, with a
/// selection haptic as the threshold is crossed. Release velocity carries
/// into the spring. Every action is also exposed to assistive technologies
/// as a custom semantics action, since swiping is not available there.
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    required this.child,
    this.leading,
    this.trailing = const [],
    this.fullSwipeFraction = 0.55,
    super.key,
  });

  final Widget child;
  final SwipeAction? leading;

  /// Outermost (full-swipe) action first.
  final List<SwipeAction> trailing;
  final double fullSwipeFraction;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  static const double _buttonWidth = 74;

  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );
  double _width = 0;
  bool _armed = false;

  double get _leadingWidth => widget.leading == null ? 0 : _buttonWidth;
  double get _trailingWidth => widget.trailing.length * _buttonWidth;
  double get _fullSwipe => _width * widget.fullSwipeFraction;
  bool get _isOpen => _offset.value.abs() > 0.5;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) => _offset.stop();

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_offset.value + details.delta.dx).clamp(
      widget.trailing.isEmpty ? 0.0 : -_width,
      widget.leading == null ? 0.0 : _width,
    );
    _offset.value = next;
    final armed = next.abs() >= _fullSwipe;
    if (armed != _armed) {
      setState(() => _armed = armed);
      final haptics = registeredHaptics;
      if (haptics != null) unawaited(haptics.selection());
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final x = _offset.value;
    final velocity = details.primaryVelocity ?? 0;
    if (_armed) {
      _armed = false;
      _trigger(x > 0 ? widget.leading! : widget.trailing.first);
      return;
    }
    final double target;
    if (x > 0) {
      target = (x > _leadingWidth / 2 || velocity > 400) && velocity > -400
          ? _leadingWidth
          : 0;
    } else {
      target = (-x > _trailingWidth / 2 || velocity < -400) && velocity < 400
          ? -_trailingWidth
          : 0;
    }
    _animateTo(target, velocity);
  }

  void _trigger(SwipeAction action) {
    action.onTriggered();
    _animateTo(0, 0);
  }

  void _close() => _animateTo(0, 0);

  void _animateTo(double target, double velocity) {
    final motion = context.motion;
    if (motion.reduced) {
      unawaited(
        _offset.animateTo(
          target,
          duration: KairoMotion.reducedDuration,
          curve: Curves.easeInOut,
        ),
      );
      return;
    }
    unawaited(
      _offset.animateWith(
        SpringSimulation(
          KairoSpring.smooth.description,
          _offset.value,
          target,
          velocity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semanticsActions = {
      if (widget.leading case final a?)
        CustomSemanticsAction(label: a.label): a.onTriggered,
      for (final a in widget.trailing)
        CustomSemanticsAction(label: a.label): a.onTriggered,
    };

    return Semantics(
      customSemanticsActions: semanticsActions,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _offset,
              builder: (context, child) {
                final x = _offset.value;
                return Stack(
                  children: [
                    if (x > 0.5 && widget.leading != null)
                      Positioned.fill(child: _leadingBackground(x)),
                    if (x < -0.5 && widget.trailing.isNotEmpty)
                      Positioned.fill(child: _trailingBackground(-x)),
                    Transform.translate(
                      offset: Offset(x, 0),
                      // Same tree open or closed, so the row keeps its
                      // state; while open, a tap closes it instead.
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isOpen ? _close : null,
                        child: AbsorbPointer(absorbing: _isOpen, child: child),
                      ),
                    ),
                  ],
                );
              },
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  Widget _leadingBackground(double width) {
    final action = widget.leading!;
    return Align(
      alignment: Alignment.centerLeft,
      child: _ActionButton(
        action: action,
        width: width,
        alignment: Alignment.centerLeft,
        onTap: () => _trigger(action),
      ),
    );
  }

  Widget _trailingBackground(double width) {
    final actions = widget.trailing;
    // Past the open width, the outermost action grows to fill the swipe.
    final extra = math.max(0, width - _trailingWidth);
    final share = math.min(width, _trailingWidth) / actions.length;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++)
            _ActionButton(
              action: actions[i],
              width: i == 0 ? share + extra : share,
              alignment: i == 0 && _armed
                  ? Alignment.centerLeft
                  : Alignment.center,
              onTap: () => _trigger(actions[i]),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.width,
    required this.alignment,
    required this.onTap,
  });

  final SwipeAction action;
  final double width;
  final Alignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = action.foreground ?? context.appColors.onTint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        color: action.color,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRect(
          child: OverflowBox(
            maxWidth: _SwipeActionsState._buttonWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, color: fg, size: 22),
                const SizedBox(height: 2),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.2),
                  style: context.typography.caption1.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
