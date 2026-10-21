import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:kairotasks/features/calendar/domain/entities/calendar_palette.dart';

void main() {
  test('palette uses the color I chose for each friend', () {
    final palette = CalendarRepositoryImpl.paletteFrom(
      {'color': '#111111'},
      [
        {
          'requester_id': 'me',
          'addressee_id': 'ana',
          'requester_color': '#AAAAAA',
          'addressee_color': '#ZZZZZZ',
        },
        {
          'requester_id': 'luis',
          'addressee_id': 'me',
          'requester_color': '#ZZZZZZ',
          'addressee_color': null,
        },
      ],
      'me',
    );

    expect(palette.ownColor, '#111111');
    expect(palette.friendColors, {
      'ana': '#AAAAAA',
      'luis': CalendarPalette.defaultFriendColor,
    });
    expect(palette.colorFor('me', 'me'), '#111111');
    expect(
      palette.colorFor('stranger', 'me'),
      CalendarPalette.defaultFriendColor,
    );
  });

  group('friend tasks', () {
    Map<String, dynamic> row({String? visibility, bool shared = false}) => {
      'id': 't1',
      'owner_id': 'ana',
      'title': 'Dentist',
      'description': 'Cleaning',
      'priority': 'high',
      'status': 'pending',
      'start_date': '2026-10-20T10:00:00.000Z',
      'due_date': '2026-10-20T11:00:00.000Z',
      'created_at': '2026-10-01T00:00:00.000Z',
      'calendar_visibility': visibility,
      'is_shared_with_me': shared,
    };

    test('public calendars show the task', () {
      final f = CalendarRepositoryImpl.friendTaskFrom(
        row(visibility: 'public'),
      );
      expect(f.isPrivate, isFalse);
      expect(f.task.title, 'Dentist');
      expect(f.task.description, 'Cleaning');
    });

    test('private calendars only expose busy time', () {
      final f = CalendarRepositoryImpl.friendTaskFrom(
        row(visibility: 'private'),
      );
      expect(f.isPrivate, isTrue);
      expect(f.task.title, isEmpty);
      expect(f.task.description, isNull);
      expect(f.task.startDate, DateTime.utc(2026, 10, 20, 10).toLocal());
    });

    test('a task shared with me is visible even on a private calendar', () {
      final f = CalendarRepositoryImpl.friendTaskFrom(
        row(visibility: 'private', shared: true),
      );
      expect(f.isPrivate, isFalse);
    });

    test('unknown visibility is treated as private', () {
      expect(CalendarRepositoryImpl.friendTaskFrom(row()).isPrivate, isTrue);
    });
  });
}
