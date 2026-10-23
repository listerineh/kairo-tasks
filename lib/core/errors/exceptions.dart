class ServerException implements Exception {
  const ServerException({this.message = 'Server error occurred', this.code});
  final String message;

  /// The Postgres SQLSTATE when there is one (e.g. `23505`, duplicate key).
  final String? code;
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache error occurred'});
  final String message;
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection'});
  final String message;
}
