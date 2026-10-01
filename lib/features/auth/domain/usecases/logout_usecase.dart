import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Business logic use case for signing out the user session.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> execute() {
    return _repository.logout();
  }
}
