import 'package:menstracker/features/auth/domain/entities/user_entity.dart';
import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Business logic use case for retrieving the current active user.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> execute() {
    return _repository.getCurrentUser();
  }

  Stream<UserEntity?> get authStateChanges => _repository.authStateChanges;
}
