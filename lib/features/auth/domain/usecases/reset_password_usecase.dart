import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Business logic use case for sending a password reset email.
class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<void> execute({required String email}) {
    return _repository.sendPasswordResetEmail(email: email.trim());
  }
}
