import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Use case for securely changing the authenticated user's password.
class ChangePasswordUseCase {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  Future<void> execute({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
