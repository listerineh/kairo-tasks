import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/friend.dart';
import 'person_avatar.dart';

/// Friends in a horizontal row of avatars on a white card. Tapping one opens
/// their sheet.
class FriendsStrip extends StatelessWidget {
  const FriendsStrip({required this.friends, required this.onOpen, super.key});

  final List<Friend> friends;
  final ValueChanged<Friend> onOpen;

  @override
  Widget build(BuildContext context) {
    // Names stay one line; past 1.3x the strip would need a second row.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return KairoCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in friends)
                _FriendTile(friend: f, onTap: () => onOpen(f)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = friend.displayName?.trim().isNotEmpty ?? false
        ? friend.displayName!.trim().split(RegExp(r'\s+')).first
        : friend.name;
    return Semantics(
      button: true,
      label: friend.name,
      excludeSemantics: true,
      child: Pressable(
        onPressed: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            children: [
              PersonAvatar(
                id: friend.id,
                name: friend.name,
                imageUrl: friend.avatarUrl,
                color: friend.color,
                size: 54,
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.footnote.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
