import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile & Cycle Firebase Serialization Tests', () {
    test('CycleProfileModel toJson and fromJson preserves birth date and last period date in Firestore format', () {
      final birthDate = DateTime(1997, 8, 15);
      final lastPeriodDate = DateTime(2026, 9, 28);
      final lastPeriodEndDate = DateTime(2026, 10, 3);

      final cycleModel = CycleProfileModel(
        trackingGoal: 'fertility_ovulation',
        lastPeriodDate: lastPeriodDate,
        lastPeriodEndDate: lastPeriodEndDate,
        cycleLength: 30,
        periodDuration: 6,
        regularity: 'regular',
        birthDate: birthDate,
        createdAt: DateTime(2026, 1, 1),
      );

      final firestoreMap = cycleModel.toJson();
      expect(firestoreMap['birthDate'], isA<Timestamp>());
      expect((firestoreMap['birthDate'] as Timestamp).toDate().year, 1997);
      expect((firestoreMap['lastPeriodDate'] as Timestamp).toDate().month, 9);
      expect(firestoreMap['cycleLength'], 30);
      expect(firestoreMap['periodDuration'], 6);

      final restored = CycleProfileModel.fromJson(firestoreMap);
      expect(restored.birthDate.year, 1997);
      expect(restored.birthDate.month, 8);
      expect(restored.birthDate.day, 15);
      expect(restored.lastPeriodDate.year, 2026);
      expect(restored.lastPeriodDate.month, 9);
      expect(restored.lastPeriodDate.day, 28);
      expect(restored.cycleLength, 30);
      expect(restored.periodDuration, 6);
      expect(restored.trackingGoal, 'fertility_ovulation');
    });

    test('UserProfileData fromJson parses Firestore document map correctly and keeps birthDate in sync', () {
      final birthDate = DateTime(1995, 3, 22);
      final lmp = DateTime(2026, 9, 10);

      final firestoreDoc = <String, dynamic>{
        'name': 'Wiyanda Susanti',
        'email': 'wiyanda@example.com',
        'birthDate': Timestamp.fromDate(birthDate),
        'birthYear': birthDate.year,
        'hasCompletedSetup': true,
        'cycleProfile': {
          'trackingGoal': 'predict_period',
          'lastPeriodDate': Timestamp.fromDate(lmp),
          'cycleLength': 29,
          'periodDuration': 5,
          'regularity': 'regular',
          'birthDate': Timestamp.fromDate(birthDate),
          'birthYear': birthDate.year,
        },
        'healthProfile': {
          'reproductiveStatus': 'planning_pregnancy',
          'contraception': 'none',
          'gynecologicalConditions': ['none'],
          'familyMedicalHistory': ['none'],
        },
      };

      final restored = UserProfileData.fromJson(firestoreDoc, uid: 'user_test_99');

      expect(restored.name, 'Wiyanda Susanti');
      expect(restored.email, 'wiyanda@example.com');
      expect(restored.birthDate.year, 1995);
      expect(restored.birthDate.month, 3);
      expect(restored.birthDate.day, 22);
      expect(restored.cycleProfile.birthDate.year, 1995);
      expect(restored.cycleProfile.lastPeriodDate.year, 2026);
      expect(restored.healthProfile?.reproductiveStatus, 'planning_pregnancy');
    });
  });
}
