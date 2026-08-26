import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class ProfileColorSheet extends StatefulWidget {
  const ProfileColorSheet({
    required this.initialColor,
    super.key,
  });

  final String initialColor;

  @override
  State<ProfileColorSheet> createState() => _ProfileColorSheetState();
}

class _ProfileColorSheetState extends State<ProfileColorSheet> {
  late String _selectedColor;

  static const _palette = [
    '#4A6741',
    '#5A7C51',
    '#6B8C7A',
    '#6B8FA3',
    '#7A7A8C',
    '#8C7B6B',
    '#9B7A5B',
    '#A36B6B',
    '#8E6B9B',
    '#6B5B8C',
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'My task color',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'This color will be used for your tasks in the calendar',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                spacing: AppSpacing.spacing12,
                runSpacing: AppSpacing.spacing12,
                alignment: WrapAlignment.center,
                children: _palette.map((hex) {
                  final selected = hex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _parseColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colors.textPrimary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedColor),
                  child: const Text('Save Color'),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
