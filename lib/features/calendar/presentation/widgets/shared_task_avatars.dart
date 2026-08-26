import 'package:flutter/material.dart';

class SharedTaskAvatars extends StatelessWidget {
  const SharedTaskAvatars({
    required this.sharedWith,
    this.radius = 7.0,
    super.key,
  });

  final List<Map<String, dynamic>> sharedWith;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (sharedWith.isEmpty) return const SizedBox.shrink();

    final max = sharedWith.length > 3 ? 3 : sharedWith.length;
    final overflow = sharedWith.length - max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List<Widget>.generate(max, (i) {
          final url = sharedWith[i]['avatar_url'] as String?;
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: CircleAvatar(
              radius: radius,
              backgroundImage: url != null && url.isNotEmpty
                  ? NetworkImage(url)
                  : null,
              child: url == null || url.isEmpty
                  ? Text(
                      _initial(sharedWith[i]),
                      style: TextStyle(
                        fontSize: radius,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : null,
            ),
          );
        }),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '+$overflow',
              style: TextStyle(
                fontSize: radius + 2,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  String _initial(Map<String, dynamic> profile) {
    final displayName =
        (profile['display_name'] as String?) ??
        (profile['username'] as String?) ??
        '';
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
