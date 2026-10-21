import 'package:flutter/cupertino.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/person.dart';
import 'person_avatar.dart';

/// A friend request on the `ink` surface: who it is, decline and accept
/// (lime, the one accent on ink).
class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final from = request.from;
    final username = from.username;

    return KairoCard(
      style: KairoCardStyle.ink,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          PersonAvatar(id: from.id, name: from.name, imageUrl: from.avatarUrl),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wantsToJoin(from.name),
                  style: context.typography.headline.copyWith(
                    color: colors.onInk,
                  ),
                ),
                if (username != null && username.isNotEmpty)
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.footnote.copyWith(
                      color: colors.onInkSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          _RoundButton(
            icon: CupertinoIcons.xmark,
            label: l10n.declineRequestFrom(from.name),
            background: Color.alphaBlend(
              colors.onInk.withValues(alpha: 0.1),
              colors.ink,
            ),
            foreground: colors.onInk,
            onTap: onDecline,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          _RoundButton(
            icon: CupertinoIcons.checkmark_alt,
            label: l10n.acceptRequestFrom(from.name),
            background: colors.lime,
            foreground: colors.onLime,
            onTap: onAccept,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Pressable(
      onPressed: onTap,
      child: Container(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: foreground),
      ),
    ),
  );
}
