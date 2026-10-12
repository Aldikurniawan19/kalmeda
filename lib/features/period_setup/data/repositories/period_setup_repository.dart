import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:menstracker/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/record/data/datasources/record_remote_data_source.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';

/// Contract and implementation for saving initial cycle and health setup profiles directly to Firebase.
class PeriodSetupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final RecordRemoteDataSource _recordDataSource;

  PeriodSetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    RecordRemoteDataSource? recordDataSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _recordDataSource = recordDataSource ?? RecordRepositoryImpl();

  /// Saves the complete baseline setup profile (cycle + health) directly to Firebase and marks setup as completed.
  Future<void> saveBaselineSetup(
    CycleProfileModel profile, {
    HealthProfileModel? healthProfile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum masuk.');
    }

    final userName = user.displayName ?? '';
    final userEmail = user.email ?? '';

    // 1. Update user profile document directly in Firestore: users/{uid}
    final payload = <String, dynamic>{
      'name': userName,
      'email': userEmail,
      'birthDate': Timestamp.fromDate(profile.birthDate),
      'birthYear': profile.birthYear,
      'hasCompletedSetup': true,
      'cycleProfile': profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (healthProfile != null) {
      payload['healthProfile'] = healthProfile.toJson();
    }

    await _firestore.collection('users').doc(user.uid).set(
          payload,
          SetOptions(merge: true),
        );

    // 2. Persist completion flag to local session cache
    try {
      final authLocal = AuthLocalDataSourceImpl();
      await authLocal.setSetupCompleted(true);
      if (userName.isNotEmpty) {
        await authLocal.updateUserName(userName);
      }
    } catch (_) {}

    // 3. Create initial cycle record in Firebase for the last period start date
    try {
      final initialRecord = CycleRecordModel(
        id: '',
        userId: user.uid,
        date: profile.lastPeriodDate,
        flowIndex: 3, // Medium flow
        moodIndex: 0, // Normal / Calm
        symptoms: const [],
        waterCups: 8,
        exerciseIndex: 1,
        notes: 'Hari pertama siklus menstruasi terakhir (data awal)',
        createdAt: DateTime.now(),
      );

      await _recordDataSource.saveRecord(initialRecord);
    } catch (_) {
      // Non-blocking if record creation encounters minor failure
    }
  }

  /// Retrieves the saved cycle profile directly from Firebase for current user.
  Future<CycleProfileModel?> getBaselineSetup() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final cycleProfileData = data['cycleProfile'] as Map<String, dynamic>?;
      if (cycleProfileData == null) return null;

      return CycleProfileModel.fromJson(cycleProfileData);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the saved health profile directly from Firebase for current user.
  Future<HealthProfileModel?> getHealthProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final healthProfileData = data['healthProfile'] as Map<String, dynamic>?;
      if (healthProfileData == null) return null;

      return HealthProfileModel.fromJson(healthProfileData);
    } catch (_) {
      return null;
    }
  }
}

