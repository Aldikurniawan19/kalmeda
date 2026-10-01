import 'package:menstracker/features/auth/domain/entities/user_entity.dart';
import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Business logic use case for user login.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<UserEntity> execute({
    required String email,
    required String password,
  }) {
    return _repository.login(
      email: email.trim(),
      password: password,
    );
  }
}
