import 'package:equatable/equatable.dart';

/// The signed-in user's profile.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    this.avatarUrl,
    this.color,
    this.calendarPublic = false,
    this.memberSince,
  });

  final String id;
  final String displayName;
  final String username;
  final String? email;
  final String? avatarUrl;

  /// My color in friends' calendars (`#RRGGBB`).
  final String? color;

  /// Whether accepted friends see my dated tasks in their calendar.
  final bool calendarPublic;

  final DateTime? memberSince;

  Profile copyWith({String? color, bool? calendarPublic}) => Profile(
    id: id,
    displayName: displayName,
    username: username,
    email: email,
    avatarUrl: avatarUrl,
    color: color ?? this.color,
    calendarPublic: calendarPublic ?? this.calendarPublic,
    memberSince: memberSince,
  );

  @override
  List<Object?> get props => [
    id,
    displayName,
    username,
    email,
    avatarUrl,
    color,
    calendarPublic,
    memberSince,
  ];
}

/// What the edit sheet saves. [avatarPath] is a new local photo to upload.
class ProfileDraft extends Equatable {
  const ProfileDraft({
    required this.displayName,
    required this.username,
    this.avatarPath,
  });

  final String displayName;
  final String username;
  final String? avatarPath;

  /// Usernames are lowercase letters, digits, dots, dashes and underscores,
  /// 3 to 30 characters.
  static final usernamePattern = RegExp(r'^[a-z0-9._-]{3,30}$');

  ProfileDraft normalized() => ProfileDraft(
    displayName: displayName.trim(),
    username: username.trim().toLowerCase(),
    avatarPath: avatarPath,
  );

  @override
  List<Object?> get props => [displayName, username, avatarPath];
}
