import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

typedef ThemeCallback = void Function(ThemeMode mode);

class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({
    required this.currentMode,
    required this.onChanged,
    super.key,
  });

  final ThemeMode currentMode;
  final ThemeCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text('Appearance', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.spacing20),
            ...ThemeMode.values.map((mode) => _ThemeOption(
                  mode: mode,
                  isSelected: currentMode == mode,
                  onTap: () => onChanged(mode),
                )),
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  IconData get _icon {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_5;
      case ThemeMode.dark:
        return Icons.brightness_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent.withValues(alpha: 0.1)
              : colors.surfaceSubtle,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, color: isSelected ? colors.accent : colors.textSecondary),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                _label,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.accent : colors.textPrimary,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: colors.accent),
          ],
        ),
      ),
    );
  }
}
