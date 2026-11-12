import 'package:equatable/equatable.dart';

/// How someone found in search relates to the signed-in user.
enum Relation { none, friend, requested, incoming }

/// A profile shown in search results or in a friend request.
class Person extends Equatable {
  const Person({
    required this.id,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.relation = Relation.none,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final Relation relation;

  /// Best available name: display name, then @username.
  String get name {
    final display = displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final user = username?.trim();
    return user == null || user.isEmpty ? '' : '@$user';
  }

  Person withRelation(Relation value) => Person(
    id: id,
    displayName: displayName,
    username: username,
    avatarUrl: avatarUrl,
    relation: value,
  );

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl, relation];
}

/// A pending request someone sent me.
class FriendRequest extends Equatable {
  const FriendRequest({required this.id, required this.from});

  /// The `friendships` row id.
  final String id;
  final Person from;

  @override
  List<Object?> get props => [id, from];
}
