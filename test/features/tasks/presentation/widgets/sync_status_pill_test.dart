import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/app/theme/app_theme.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_sync_status.dart';
import 'package:kairotasks/features/tasks/presentation/widgets/sync_status_pill.dart';
import 'package:kairotasks/generated/app_localizations.dart';

void main() {
  late StreamController<TaskSyncStatus> status;

  setUp(() => status = StreamController<TaskSyncStatus>());
  tearDown(() => unawaited(status.close()));

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SyncStatusPill(status: status.stream)),
    ),
  );

  testWidgets('hidden while online with nothing waiting', (tester) async {
    await pump(tester);
    status.add(const TaskSyncStatus());
    await tester.pump();
    expect(find.textContaining('Offline'), findsNothing);
    expect(find.textContaining('Syncing'), findsNothing);
  });

  testWidgets('says when offline and when changes are syncing', (tester) async {
    await pump(tester);
    status.add(const TaskSyncStatus(online: false, pending: 2));
    await tester.pump();
    expect(find.text('Offline · your changes are saved here'), findsOneWidget);

    status.add(const TaskSyncStatus(pending: 2));
    await tester.pump();
    expect(find.text('Syncing 2 changes'), findsOneWidget);
  });
}
