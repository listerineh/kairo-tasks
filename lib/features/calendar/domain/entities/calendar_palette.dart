import 'package:equatable/equatable.dart';

/// Hex colors for calendar blocks: mine, and the one I picked per friend.
class CalendarPalette extends Equatable {
  const CalendarPalette({
    this.ownColor = defaultOwnColor,
    this.friendColors = const {},
  });

  static const defaultOwnColor = '#4A6741';
  static const defaultFriendColor = '#6B8FA3';

  final String ownColor;

  /// Friend user id -> hex color.
  final Map<String, String> friendColors;

  String colorFor(String ownerId, String? me) =>
      ownerId == me ? ownColor : friendColors[ownerId] ?? defaultFriendColor;

  @override
  List<Object?> get props => [ownColor, friendColors];
}
