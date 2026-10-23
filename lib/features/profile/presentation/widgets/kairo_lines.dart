import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';

/// What Kairo says in each mood (Yo and his page).
String kairoLine(BuildContext context, MascotMood mood) {
  final l10n = context.l10n;
  return switch (mood) {
    MascotMood.idle => l10n.kairoLineIdle,
    MascotMood.focused => l10n.kairoLineFocused,
    MascotMood.happy => l10n.kairoLineHappy,
    MascotMood.sad => l10n.kairoLineSad,
    MascotMood.sleeping => l10n.kairoLineSleeping,
  };
}
