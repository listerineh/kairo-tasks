import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';

/// Centered placeholder for empty lists: symbol, title, optional message and
/// one optional action. Copy should say what to do next, not just "Nothing".
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Usually a tinted or plain `KairoButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.typography;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: MediaQuery.textScalerOf(context).scale(44),
              color: colors.labelSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: type.title3.copyWith(color: colors.label),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: type.subheadline.copyWith(color: colors.labelSecondary),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.spacing24),
            action!,
          ],
        ],
      ),
    );
  }
}
