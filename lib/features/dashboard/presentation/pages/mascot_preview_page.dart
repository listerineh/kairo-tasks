import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../widgets/mascot_widget.dart';

class MascotPreviewPage extends StatelessWidget {
  const MascotPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    const states = MascotState.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Mascot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Wrap(
              spacing: AppSpacing.spacing24,
              runSpacing: AppSpacing.spacing24,
              alignment: WrapAlignment.center,
              children: states.map((state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MascotWidget(state: state, streak: 5),
                    const SizedBox(height: AppSpacing.spacing8),
                    Text(
                      state.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
