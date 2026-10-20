import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  test('initial state is unknown', () async {
    final bloc = AuthBloc(client);
    expect(bloc.state.status, AuthStatus.unknown);
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'AuthCheckRequested without a session emits unauthenticated',
    setUp: () => when(() => auth.currentSession).thenReturn(null),
    build: () => AuthBloc(client),
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
  );
}
