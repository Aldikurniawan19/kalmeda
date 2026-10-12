import 'package:menstracker/core/error/exceptions.dart';
import 'package:menstracker/core/error/failures.dart';
import 'package:menstracker/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:menstracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:menstracker/features/auth/data/models/user_model.dart';
import 'package:menstracker/features/auth/domain/entities/user_entity.dart';
import 'package:menstracker/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] mediating between remote data source, local cache, and domain layer.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        return getCurrentUser();
      }
      // Return local cached user if available; only true logout should clear cache
      return await _localDataSource.getCachedUser();
    });
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );
      await _localDataSource.cacheUser(userModel);
      return userModel;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw AuthFailure('Gagal mendaftar: $e');
    }
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _localDataSource.cacheUser(userModel);
      return userModel;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw AuthFailure('Gagal masuk: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      throw AuthException('Gagal keluar: $e');
    } finally {
      await _localDataSource.clearUserCache();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // 1. Check local session cache for instantaneous offline availability
    final cached = await _localDataSource.getCachedUser();

    try {
      final remote = await _remoteDataSource.getCurrentUser();
      if (remote != null) {
        // Merge with local state to preserve setup completion flag if local is already true
        final mergedUser = UserModel(
          uid: remote.uid,
          name: remote.name.isNotEmpty ? remote.name : (cached?.name ?? 'Pengguna'),
          email: remote.email.isNotEmpty ? remote.email : (cached?.email ?? ''),
          hasCompletedSetup: remote.hasCompletedSetup || (cached?.hasCompletedSetup ?? false),
          createdAt: remote.createdAt ?? cached?.createdAt,
        );
        await _localDataSource.cacheUser(mergedUser);
        return mergedUser;
      } else {
        // If remote returned null (e.g. initial token loading), retain valid cached session
        return cached;
      }
    } catch (_) {
      // Fallback safely to cached user on network glitch
      return cached;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Gagal mengirim email reset kata sandi: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw AuthFailure('Gagal mengubah kata sandi: $e');
    }
  }
}
