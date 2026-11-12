import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_avatar.dart';
import '../../../calendar/presentation/widgets/calendar_colors.dart';

/// A person's calendar tone: the color I picked for them, or one chosen
/// from their id so friends without a color still look different.
CalendarTone toneFor(String id, [String? color]) {
  if (calendarColor(color) != null) return CalendarTone.of(color);
  final seed = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return CalendarTone.all[seed % CalendarTone.all.length];
}

/// [KairoAvatar] with initials on the person's tone (docs/design.md
/// § Calendar and people).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.id,
    required this.name,
    this.imageUrl,
    this.color,
    this.size = 44,
    super.key,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = toneFor(id, color);
    final light = Theme.of(context).brightness == Brightness.light;
    return KairoAvatar(
      name: name,
      imageUrl: imageUrl,
      size: size,
      background: tone.fillFor(Theme.of(context).brightness, colors.surface),
      foreground: light ? tone.ink : colors.label,
    );
  }
}
