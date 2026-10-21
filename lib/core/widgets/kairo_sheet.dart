import 'package:flutter/material.dart';

import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../extensions/context_extensions.dart';

/// Heights a [showKairoSheet] can rest at, as a fraction of the space below
/// the status bar.
enum KairoSheetDetent {
  medium(0.5),
  large(1);

  const KairoSheetDetent(this.fraction);
  final double fraction;
}

/// Sheet: grabber, raised surface, 30 pt top corners, a 50% dim behind, and
/// detents it snaps between. Opens with the `smooth` spring (a cross-fade
/// timing under reduced motion).
///
/// [builder] gets the sheet's scroll controller; pass it to the scrollable
/// so dragging the content also drags the sheet.
Future<T?> showKairoSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  List<KairoSheetDetent> detents = const [
    KairoSheetDetent.medium,
    KairoSheetDetent.large,
  ],
}) {
  assert(detents.isNotEmpty, 'A sheet needs at least one detent');
  final colors = context.appColors;
  final motion = context.motion;
  final sizes = detents.map((d) => d.fraction).toList()..sort();

  return showModalBottomSheet<T>(
    context: context,
    // Above the tab bar, like a system sheet.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    // Grouped content sits on the grouped background, rows one level up
    // (see KairoSheetScope), like iOS form sheets.
    backgroundColor: context.isDarkMode ? colors.surface : colors.background,
    barrierColor: const Color(0x800A0C0E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: AnimationStyle(
      duration: motion.duration(KairoSpring.smooth),
      reverseDuration: motion.duration(KairoSpring.smooth),
      curve: motion.curve(KairoSpring.smooth),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: sizes.first,
      minChildSize: sizes.first,
      maxChildSize: sizes.last,
      snap: sizes.length > 1,
      snapSizes: sizes.length > 2 ? sizes.sublist(1, sizes.length - 1) : null,
      builder: (context, controller) => KairoSheetScope(
        child: Column(
          children: [
            const _Grabber(),
            Expanded(child: builder(context, controller)),
          ],
        ),
      ),
    ),
  );
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 10),
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: context.appColors.labelTertiary,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}

/// Marks content shown inside [showKairoSheet], so grouped rows use the
/// raised surface and stay distinct from the sheet's background.
class KairoSheetScope extends InheritedWidget {
  const KairoSheetScope({required super.child, super.key});

  static bool isInSheet(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KairoSheetScope>() != null;

  @override
  bool updateShouldNotify(KairoSheetScope oldWidget) => false;
}
