import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/errors/exceptions.dart';
import 'package:kairotasks/core/errors/failures.dart';
import 'package:kairotasks/features/tasks/data/models/task_model.dart';
import 'package:kairotasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:kairotasks/features/tasks/domain/entities/task_entity.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockTaskRemoteDataSource dataSource;
  late TaskRepositoryImpl repository;

  final model = TaskModel(
    id: 't1',
    ownerId: 'u1',
    title: 'Write report',
    priority: 'high',
    createdAt: DateTime(2026, 10, 20),
  );

  setUpAll(() => registerFallbackValue(model));

  setUp(() {
    dataSource = MockTaskRemoteDataSource();
    repository = TaskRepositoryImpl(dataSource);
  });

  group('getTasks', () {
    test('returns entities on success', () async {
      when(() => dataSource.getTasks()).thenAnswer((_) async => [model]);

      final result = await repository.getTasks();

      expect(result.isRight(), isTrue);
      final tasks = result.getOrElse(() => []);
      expect(tasks.single.priority, TaskPriority.high);
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => dataSource.getTasks())
          .thenThrow(const ServerException(message: 'boom'));

      final result = await repository.getTasks();

      expect(
        result.fold((f) => f, (_) => null),
        const ServerFailure(message: 'boom'),
      );
    });
  });

  test('createTask sends a model built from the entity', () async {
    when(() => dataSource.createTask(any())).thenAnswer((_) async => model);

    final result = await repository.createTask(model.toEntity());

    expect(result.isRight(), isTrue);
    final sent =
        verify(() => dataSource.createTask(captureAny())).captured.single
            as TaskModel;
    expect(sent.title, 'Write report');
    expect(sent.priority, 'high');
  });

  test('deleteTask maps ServerException to ServerFailure', () async {
    when(() => dataSource.deleteTask('t1'))
        .thenThrow(const ServerException(message: 'nope'));

    final result = await repository.deleteTask('t1');

    expect(result.isLeft(), isTrue);
  });
}
