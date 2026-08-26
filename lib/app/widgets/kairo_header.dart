import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';

class KairoHeader extends StatelessWidget {
  const KairoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/app_icon.svg',
          height: 28,
        ),
        const SizedBox(width: AppSpacing.spacing8),
        Text(
          context.l10n.kairoTasks,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
