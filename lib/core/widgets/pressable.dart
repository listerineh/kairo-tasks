import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';

/// Press feedback for custom controls: shrinks slightly with the `snappy`
/// spring while held. Under reduced motion it dims instead of scaling.
///
/// Taps are never blocked by the animation, and it follows the finger: down
/// shrinks, up or cancel springs back from wherever it is.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.97,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final enabled = widget.onPressed != null;
    final pressed = _down && enabled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => _setDown(true) : null,
      onTapUp: enabled ? (_) => _setDown(false) : null,
      onTapCancel: () => _setDown(false),
      child: AnimatedOpacity(
        opacity: pressed && motion.reduced ? 0.6 : 1,
        duration: KairoMotion.reducedDuration,
        child: AnimatedScale(
          scale: pressed && !motion.reduced ? widget.pressedScale : 1,
          duration: motion.duration(KairoSpring.snappy),
          curve: motion.curve(KairoSpring.snappy),
          child: widget.child,
        ),
      ),
    );
  }
}
