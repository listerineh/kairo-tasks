import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FocusButton extends StatelessWidget {
  const FocusButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.center_focus_strong_outlined),
      onPressed: () => context.push('/focus'),
      tooltip: 'Focus mode',
    );
  }
}
