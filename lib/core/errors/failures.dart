import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable implements Exception {
  const Failure({this.message = 'An unexpected error occurred'});

  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// A nudge for the same person and task went out less than 30 minutes ago.
class NudgeTooSoonFailure extends Failure {
  const NudgeTooSoonFailure({super.message = 'Nudged recently'});
}
