import 'package:equatable/equatable.dart';

enum CalendarVisibility { public, private_ }

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.calendarVisibility = CalendarVisibility.private_,
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final CalendarVisibility calendarVisibility;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        calendarVisibility,
        createdAt,
      ];
}
