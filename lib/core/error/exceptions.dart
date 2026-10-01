/// Base exception class for data source exceptions.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown during authentication errors with Firebase Auth.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Exception thrown during Firestore or backend operations.
class ServerException extends AppException {
  const ServerException(super.message);
}
