import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/session/current_user.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/calendar_palette.dart';
import '../../domain/entities/friend_calendar.dart';
import '../../domain/repositories/calendar_repository.dart';

@LazySingleton(as: CalendarRepository)
class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._client, this._user);

  final SupabaseClient _client;
  final CurrentUser _user;

  static const _signedOut = AuthFailure(message: 'Not signed in');

  @override
  Future<Either<Failure, FriendCalendar>> loadFriendCalendar() async {
    final me = _user.id;
    if (me == null) return const Left(_signedOut);
    try {
      final profile = await _client
          .from('profiles')
          .select('color')
          .eq('id', me)
          .single();
      final friendships = await _client
          .from('friendships')
          .select(
            'requester_id, addressee_id, requester_color, addressee_color',
          )
          .or('requester_id.eq.$me,addressee_id.eq.$me')
          .eq('status', 'accepted');
      final tasks = await _client.rpc<List<dynamic>>('get_public_friend_tasks');

      return Right(
        FriendCalendar(
          palette: paletteFrom(
            profile,
            List<Map<String, dynamic>>.from(friendships),
            me,
          ),
          friendTasks: [
            for (final row in tasks.cast<Map<String, dynamic>>())
              friendTaskFrom(row),
          ],
        ),
      );
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  /// My color, plus the color I chose for each friend (stored on my side
  /// of the friendship row).
  @visibleForTesting
  static CalendarPalette paletteFrom(
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> friendships,
    String me,
  ) {
    return CalendarPalette(
      ownColor: profile['color'] as String? ?? CalendarPalette.defaultOwnColor,
      friendColors: {
        for (final f in friendships)
          if (f['requester_id'] == me)
            f['addressee_id'] as String:
                f['requester_color'] as String? ??
                CalendarPalette.defaultFriendColor
          else
            f['requester_id'] as String:
                f['addressee_color'] as String? ??
                CalendarPalette.defaultFriendColor,
      },
    );
  }

  /// A row from `get_public_friend_tasks`. Private calendars only expose
  /// busy time, unless the task is shared with me.
  @visibleForTesting
  static FriendCalendarTask friendTaskFrom(Map<String, dynamic> row) {
    final public =
        (row['calendar_visibility'] as String? ?? 'private') == 'public';
    final sharedWithMe = row['is_shared_with_me'] as bool? ?? false;
    final visible = public || sharedWithMe;
    DateTime? date(String key) =>
        row[key] == null ? null : DateTime.parse(row[key] as String).toLocal();

    return FriendCalendarTask(
      isPrivate: !visible,
      task: TaskEntity(
        id: row['id'] as String,
        ownerId: row['owner_id'] as String,
        title: visible ? row['title'] as String? ?? '' : '',
        description: visible ? row['description'] as String? : null,
        priority: TaskModel.parsePriority(row['priority'] as String?),
        status: TaskModel.parseStatus(row['status'] as String?),
        startDate: date('start_date'),
        dueDate: date('due_date'),
        createdAt: date('created_at')!,
        updatedAt: date('updated_at'),
      ),
    );
  }

  @override
  Stream<void> changes() {
    final me = _user.id;
    if (me == null) return const Stream.empty();
    final subs = <StreamSubscription<Object?>>[];
    late final StreamController<void> out;
    out = StreamController<void>(
      onListen: () {
        void ping(Object? _) => out.add(null);
        subs
          ..add(
            _client
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('id', me)
                .listen(ping, onError: out.addError),
          )
          ..add(
            _client
                .from('friendships')
                .stream(primaryKey: ['requester_id', 'addressee_id'])
                .eq('requester_id', me)
                .listen(ping, onError: out.addError),
          )
          ..add(
            _client
                .from('friendships')
                .stream(primaryKey: ['requester_id', 'addressee_id'])
                .eq('addressee_id', me)
                .listen(ping, onError: out.addError),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        // Not awaited: done is never delivered once the listener is gone.
        unawaited(out.close());
      },
    );
    return out.stream;
  }
}
