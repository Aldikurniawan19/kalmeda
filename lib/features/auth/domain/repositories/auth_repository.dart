import 'package:menstracker/features/auth/domain/entities/user_entity.dart';

/// Contract interface for authentication and user account management.
abstract class AuthRepository {
  /// Registers a new user with name, email, and password.
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  });

  /// Logs in an existing user with email and password.
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  /// Logs out the current user session.
  Future<void> logout();

  /// Gets the currently authenticated user, or null if unauthenticated.
  Future<UserEntity?> getCurrentUser();

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail({required String email});

  /// Changes the user's password after verifying the current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Stream of user authentication state changes.
  Stream<UserEntity?> get authStateChanges;
}
