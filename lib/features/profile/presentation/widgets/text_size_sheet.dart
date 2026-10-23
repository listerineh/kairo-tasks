import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/widgets/grouped_section.dart';
import '../../../../core/widgets/kairo_card.dart';

/// Follow the system text size, or pick one of
/// [PreferencesService.textScales] with a live preview.
class TextSizeSheet extends StatelessWidget {
  const TextSizeSheet({
    required this.preferences,
    required this.controller,
    super.key,
  });

  final PreferencesService preferences;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    const steps = PreferencesService.textScales;

    return ValueListenableBuilder<double?>(
      valueListenable: preferences.textScale,
      builder: (context, scale, _) {
        final system = scale == null;
        final index = system
            ? steps.indexOf(1)
            : steps.indexWhere((s) => s >= scale - 0.001);
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            0,
            AppSpacing.spacing8,
            0,
            AppSpacing.spacing32,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: Semantics(
                header: true,
                child: Text(l10n.textSize, style: context.typography.title1),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: KairoCard(
                child: Text(
                  l10n.textSizePreview,
                  style: context.typography.bodyMultiline,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            GroupedSection(
              children: [
                GroupedRow(
                  title: l10n.textSizeSystem,
                  trailing: CupertinoSwitch(
                    value: system,
                    activeTrackColor: colors.tint,
                    onChanged: (v) =>
                        preferences.setTextScale(v ? null : steps[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16,
                    vertical: AppSpacing.spacing8,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          'A',
                          textScaler: TextScaler.noScaling,
                          style: context.typography.footnote.copyWith(
                            color: system
                                ? colors.labelTertiary
                                : colors.labelSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Slider.adaptive(
                          value: index.toDouble(),
                          max: (steps.length - 1).toDouble(),
                          divisions: steps.length - 1,
                          activeColor: colors.tint,
                          label: '${(steps[index] * 100).round()}%',
                          semanticFormatterCallback: (v) =>
                              '${(steps[v.round()] * 100).round()}%',
                          onChanged: system
                              ? null
                              : (v) =>
                                    preferences.setTextScale(steps[v.round()]),
                        ),
                      ),
                      ExcludeSemantics(
                        child: Text(
                          'A',
                          textScaler: TextScaler.noScaling,
                          style: context.typography.title2.copyWith(
                            color: system
                                ? colors.labelTertiary
                                : colors.labelSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
