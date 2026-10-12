import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menstracker/core/error/exceptions.dart';
import 'package:menstracker/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';

/// Contract interface for Profile remote data operations directly on Firebase.
abstract class ProfileRemoteDataSource {
  Future<UserProfileData> getUserProfile();

  Future<void> updateUserProfile({
    required String name,
    required DateTime birthDate,
    required CycleProfileModel cycleProfile,
    HealthProfileModel? healthProfile,
  });
}

/// Firebase implementation of [ProfileRemoteDataSource].
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfileData> getUserProfile() async {
    User? user = _firebaseAuth.currentUser;
    if (user == null) {
      try {
        user = await _firebaseAuth.authStateChanges().first.timeout(
          const Duration(milliseconds: 2000),
          onTimeout: () => _firebaseAuth.currentUser,
        );
      } catch (_) {
        user = _firebaseAuth.currentUser;
      }
    }

    if (user == null) {
      throw const AuthException('Pengguna belum masuk. Silakan login kembali.');
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        // Return default user profile and persist initial baseline to Firebase Firestore
        final defaultProfile = UserProfileData(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          birthDate: DateTime(2000, 1, 1),
          cycleProfile: CycleProfileModel(
            trackingGoal: 'predict_period',
            lastPeriodDate: DateTime.now().subtract(const Duration(days: 7)),
            cycleLength: 28,
            periodDuration: 5,
            regularity: 'regular',
            birthDate: DateTime(2000, 1, 1),
          ),
          healthProfile: const HealthProfileModel(),
        );

        await _firestore.collection('users').doc(user.uid).set({
          'name': defaultProfile.name,
          'email': defaultProfile.email,
          'birthDate': Timestamp.fromDate(defaultProfile.birthDate),
          'birthYear': defaultProfile.birthDate.year,
          'cycleProfile': defaultProfile.cycleProfile.toJson(),
          'healthProfile': defaultProfile.healthProfile?.toJson(),
          'hasCompletedSetup': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return defaultProfile;
      }

      final data = doc.data()!;
      return UserProfileData.fromJson(
        data,
        uid: user.uid,
        fallbackEmail: user.email,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat profil pengguna dari Firebase.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Terjadi kendala saat mengambil data profil: $e');
    }
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required DateTime birthDate,
    required CycleProfileModel cycleProfile,
    HealthProfileModel? healthProfile,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('Pengguna belum masuk.');
    }

    // Ensure cycleProfile matches the updated birthDate
    final effectiveCycleProfile = cycleProfile.copyWith(birthDate: birthDate);

    try {
      // 1. Update Firebase Auth display name if changed
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      // 2. Prepare payload to update users/{uid} document directly in Firestore
      final updateData = <String, dynamic>{
        'name': name,
        'email': user.email ?? '',
        'birthDate': Timestamp.fromDate(birthDate),
        'birthYear': birthDate.year,
        'cycleProfile': effectiveCycleProfile.toJson(),
        'hasCompletedSetup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (healthProfile != null) {
        updateData['healthProfile'] = healthProfile.toJson();
      }

      await _firestore.collection('users').doc(user.uid).set(
            updateData,
            SetOptions(merge: true),
          );

      // Update session login name cache
      try {
        await AuthLocalDataSourceImpl().updateUserName(name);
        await AuthLocalDataSourceImpl().setSetupCompleted(true);
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Gagal memperbarui nama pengguna.');
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal menyimpan perubahan ke database Firebase.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Gagal memperbarui informasi profil: $e');
    }
  }
}

