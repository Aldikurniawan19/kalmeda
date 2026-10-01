/// Base failure class for application errors.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure class specifically for authentication and account operations.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure class for server and database errors.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure class for network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Koneksi internet bermasalah. Periksa jaringan kamu.']);
}
