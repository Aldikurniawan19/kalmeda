import 'package:menstracker/features/auth/domain/entities/user_entity.dart';
import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Business logic use case for registering a new user.
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<UserEntity> execute({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
