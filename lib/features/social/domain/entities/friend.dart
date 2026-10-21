import 'package:equatable/equatable.dart';

/// Someone with an accepted friendship with the signed-in user.
class Friend extends Equatable {
  const Friend({
    required this.id,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  /// Best available name: display name, then @username.
  String get name {
    final display = displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final user = username?.trim();
    return user == null || user.isEmpty ? '' : '@$user';
  }

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl];
}
