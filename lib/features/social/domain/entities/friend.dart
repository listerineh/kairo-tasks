import 'package:equatable/equatable.dart';

/// Someone with an accepted friendship with the signed-in user.
class Friend extends Equatable {
  const Friend({
    required this.id,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.friendshipId,
    this.color,
    this.iAsked = false,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  /// The `friendships` row; needed to recolor or remove the friend.
  final String? friendshipId;

  /// The color I picked for this friend (`#RRGGBB`), if any.
  final String? color;

  /// Whether I sent the original request: decides which color column
  /// (`requester_color` / `addressee_color`) is mine.
  final bool iAsked;

  /// Best available name: display name, then @username.
  String get name {
    final display = displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final user = username?.trim();
    return user == null || user.isEmpty ? '' : '@$user';
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    username,
    avatarUrl,
    friendshipId,
    color,
    iAsked,
  ];
}
