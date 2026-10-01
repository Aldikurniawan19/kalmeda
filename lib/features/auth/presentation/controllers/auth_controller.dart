import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:menstracker/core/error/failures.dart';
import 'package:menstracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:menstracker/features/auth/domain/entities/user_entity.dart';
import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:menstracker/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:menstracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:menstracker/features/auth/domain/usecases/login_usecase.dart';
import 'package:menstracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:menstracker/features/auth/domain/usecases/register_usecase.dart';
import 'package:menstracker/features/auth/domain/usecases/reset_password_usecase.dart';

/// State status enumeration for authentication operations.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Controller managing user authentication state and business logic workflows.
class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();

  factory AuthController() => _instance;

  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  AuthController._internal({
    AuthRepository? repository,
  })  : _registerUseCase = RegisterUseCase(repository ?? AuthRepositoryImpl()),
        _loginUseCase = LoginUseCase(repository ?? AuthRepositoryImpl()),
        _logoutUseCase = LogoutUseCase(repository ?? AuthRepositoryImpl()),
        _getCurrentUserUseCase = GetCurrentUserUseCase(repository ?? AuthRepositoryImpl()),
        _resetPasswordUseCase = ResetPasswordUseCase(repository ?? AuthRepositoryImpl()),
        _changePasswordUseCase = ChangePasswordUseCase(repository ?? AuthRepositoryImpl());

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isNotEmpty;

  /// Sets current user setup status as completed.
  void setSetupCompleted() {
    if (_currentUser != null) {
      _currentUser = UserEntity(
        uid: _currentUser!.uid,
        name: _currentUser!.name,
        email: _currentUser!.email,
        hasCompletedSetup: true,
        createdAt: _currentUser!.createdAt,
      );
      notifyListeners();
    }
  }

  /// Checks the current session on app startup.
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _getCurrentUserUseCase.execute();
      if (user != null && user.isNotEmpty) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Registers a new account with Firebase.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _registerUseCase.execute(
        name: name,
        email: email,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logs in an existing account with Firebase.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginUseCase.execute(
        email: email,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal masuk: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      await _resetPasswordUseCase.execute(email: email);
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengirim email reset: $e';
      notifyListeners();
      return false;
    }
  }

  /// Changes password for currently authenticated user.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _changePasswordUseCase.execute(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengubah kata sandi: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logs out the user and clears session.
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _logoutUseCase.execute();
    } catch (_) {
      // Ignore logout cleanup error
    }

    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Clears any transient error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
