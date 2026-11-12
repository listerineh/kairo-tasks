import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';

/// Entrance for cards on a new screen: rises 14 px and fades in, [index]
/// steps of 60 ms after the first (docs/design.md § Motion). Under reduced
/// motion the child appears without moving.
class KairoEntrance extends StatefulWidget {
  const KairoEntrance({required this.child, this.index = 0, super.key});

  final Widget child;

  /// Position in the cascade; 0 starts right away.
  final int index;

  static const step = Duration(milliseconds: 60);
  static const rise = 14.0;

  @override
  State<KairoEntrance> createState() => _KairoEntranceState();
}

class _KairoEntranceState extends State<KairoEntrance> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = KairoEntrance.step * widget.index;
    if (delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    } else {
      _timer = Timer(delay, _show);
    }
  }

  void _show() {
    if (mounted) setState(() => _shown = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    if (motion.reduced) return widget.child;
    final duration = motion.duration(KairoSpring.smooth);
    final curve = motion.curve(KairoSpring.smooth);

    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        transform: Matrix4.translationValues(
          0,
          _shown ? 0 : KairoEntrance.rise,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}
