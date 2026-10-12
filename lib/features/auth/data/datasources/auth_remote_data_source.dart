import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:menstracker/core/error/exceptions.dart';
import 'package:menstracker/features/auth/data/models/user_model.dart';

/// Contract interface for Auth remote data source.
abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Stream<User?> get authStateChanges;
}

/// Firebase implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Pendaftaran akun gagal. Silakan coba beberapa saat lagi.');
      }

      // Update user display name in Firebase Auth
      await user.updateDisplayName(name);

      // Create user document in Firestore: users/{uid}
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson(), SetOptions(merge: true));

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Terjadi kendala pada server database.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Gagal mendaftarkan akun: $e');
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Pengguna tidak ditemukan.');
      }

      // Fetch user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromJson(userDoc.data()!, docId: user.uid);
      }

      // Fallback: create Firestore profile if doc does not exist
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? (email.split('@').first),
        email: user.email ?? email,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson(), SetOptions(merge: true));

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Terjadi kendala pada server database.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Gagal masuk ke akun: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Gagal keluar dari akun: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        // Asynchronously await initial auth token restoration from native keystore
        try {
          user = await _firebaseAuth.authStateChanges().first.timeout(
            const Duration(milliseconds: 2500),
            onTimeout: () => _firebaseAuth.currentUser,
          );
        } catch (_) {
          user = _firebaseAuth.currentUser;
        }
      }

      if (user == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromJson(doc.data()!, docId: user.uid);
        }
      } catch (firestoreError) {
        // Fallback gracefully if Firestore is offline or slow
      }

      return UserModel(
        uid: user.uid,
        name: user.displayName ?? (user.email?.split('@').first ?? 'Pengguna'),
        email: user.email ?? '',
        hasCompletedSetup: false,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      final fallbackUser = _firebaseAuth.currentUser;
      if (fallbackUser != null) {
        return UserModel(
          uid: fallbackUser.uid,
          name: fallbackUser.displayName ?? (fallbackUser.email?.split('@').first ?? 'Pengguna'),
          email: fallbackUser.email ?? '',
          hasCompletedSetup: false,
          createdAt: DateTime.now(),
        );
      }
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Gagal mengirim tautan reset kata sandi: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('Sesi masuk tidak ditemukan. Silakan login kembali.');
    }

    try {
      // 1. Re-authenticate user with current password credentials
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthException('Kata sandi saat ini yang Anda masukkan tidak sesuai.');
      } else if (e.code == 'weak-password') {
        throw const AuthException('Kata sandi baru terlalu lemah. Gunakan minimal 6 karakter kombinasi huruf dan angka.');
      } else if (e.code == 'requires-recent-login') {
        throw const AuthException('Sesi Anda sudah terlalu lama. Silakan keluar dan masuk kembali untuk mengubah kata sandi.');
      }
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Gagal mengubah kata sandi: $e');
    }
  }

  /// Maps Firebase Auth error codes to user-friendly Indonesian messages without emojis.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk ke akun kamu.';
      case 'invalid-email':
        return 'Format alamat email tidak valid. Periksa kembali penulisan email.';
      case 'operation-not-allowed':
        return 'Metode pendaftaran ini sedang dinonaktifkan di pengaturan server.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter kombinasi huruf dan angka.';
      case 'user-disabled':
        return 'Akun dengan email ini telah dinonaktifkan oleh administrator.';
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan. Silakan lakukan pendaftaran.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi yang kamu masukkan salah. Periksa kembali.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan masuk yang gagal. Tunggu beberapa saat sebelum mencoba lagi.';
      case 'network-request-failed':
        return 'Gagal terhubung ke jaringan. Pastikan koneksi internet kamu aktif.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi. Silakan coba lagi.';
    }
  }
}
