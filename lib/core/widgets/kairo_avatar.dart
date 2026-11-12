import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Circular avatar: the photo when it loads, otherwise initials on a soft
/// tint. Always announces the person's name.
class KairoAvatar extends StatelessWidget {
  const KairoAvatar({
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.background,
    this.foreground,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// Initials circle colors; default `tintSoft` and `tint`. Juntos passes a
  /// friend's calendar tone.
  final Color? background;
  final Color? foreground;

  /// Up to two initials from the first and last words.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final initials = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background ?? colors.tintSoft,
      ),
      child: Center(
        child: Text(
          initialsOf(name),
          // Sized to the circle, not to Dynamic Type: the name is in semantics.
          textScaler: TextScaler.noScaling,
          style: context.typography.headline.copyWith(
            fontSize: size * 0.4,
            height: 1,
            letterSpacing: 0,
            color: foreground ?? colors.tint,
          ),
        ),
      ),
    );

    final url = imageUrl;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? initials
            : ClipOval(
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => initials,
                ),
              ),
      ),
    );
  }
}
