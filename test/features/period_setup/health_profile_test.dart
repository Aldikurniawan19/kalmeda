import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_expert_synthesizer.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthProfileModel Tests', () {
    test('Correctly serializes and deserializes default model', () {
      const model = HealthProfileModel();
      final json = model.toJson();

      expect(json['reproductiveStatus'], 'single');
      expect(json['activityLevel'], 'moderate');
      expect(json['contraception'], 'none');
      expect(json['gynecologicalConditions'], ['none']);
      expect(json['familyMedicalHistory'], ['none']);
      expect(json['menarcheAge'], isNull);

      final deserialized = HealthProfileModel.fromJson(json);
      expect(deserialized.reproductiveStatus, 'single');
      expect(deserialized.activityLevel, 'moderate');
      expect(deserialized.contraception, 'none');
      expect(deserialized.gynecologicalConditions, ['none']);
      expect(deserialized.familyMedicalHistory, ['none']);
    });

    test('Correctly serializes and deserializes custom medical profile', () {
      final model = HealthProfileModel(
        reproductiveStatus: 'planning_pregnancy',
        menarcheAge: 12,
        activityLevel: 'active',
        contraception: 'none',
        gynecologicalConditions: const ['pcos', 'anemia'],
        familyMedicalHistory: const ['pcos'],
        createdAt: DateTime(2026, 1, 1),
      );

      final json = model.toJson();
      expect(json['reproductiveStatus'], 'planning_pregnancy');
      expect(json['menarcheAge'], 12);
      expect(json['gynecologicalConditions'], ['pcos', 'anemia']);
      expect(json['familyMedicalHistory'], ['pcos']);

      final deserialized = HealthProfileModel.fromJson(json);
      expect(deserialized.reproductiveStatus, 'planning_pregnancy');
      expect(deserialized.menarcheAge, 12);
      expect(deserialized.gynecologicalConditions, contains('pcos'));
      expect(deserialized.gynecologicalConditions, contains('anemia'));
      expect(deserialized.familyMedicalHistory, contains('pcos'));
    });

    test('toClinicalContextString generates accurate medical summary', () {
      final model = HealthProfileModel(
        reproductiveStatus: 'planning_pregnancy',
        menarcheAge: 12,
        activityLevel: 'moderate',
        contraception: 'none',
        gynecologicalConditions: const ['pcos'],
        familyMedicalHistory: const ['pcos'],
      );

      final contextStr = model.toClinicalContextString(
        age: 25,
        cycleLength: 30,
        periodDuration: 5,
        regularity: 'regular',
      );

      expect(contextStr, contains('Usia 25 tahun'));
      expect(contextStr, contains('Panjang siklus 30 hari'));
      expect(contextStr, contains('Merencanakan Kehamilan (Promil)'));
      expect(contextStr, contains('PCOS (Sindrom Ovarium Polikistik)'));
      expect(contextStr, contains('Usia Menstruasi Pertama (Menarche): 12 tahun'));
    });

    test('Respects user privacy when prefer_not_to_say is chosen', () {
      const model = HealthProfileModel(
        reproductiveStatus: 'prefer_not_to_say',
        contraception: 'prefer_not_to_say',
        gynecologicalConditions: ['prefer_not_to_say'],
        familyMedicalHistory: ['prefer_not_to_say'],
        activityLevel: 'prefer_not_to_say',
      );

      final contextStr = model.toClinicalContextString(
        age: 22,
        cycleLength: 28,
        periodDuration: 5,
      );

      // Sensitive fields set to prefer_not_to_say should not be revealed
      expect(contextStr, isNot(contains('Status Reproduksi:')));
      expect(contextStr, isNot(contains('Kontrasepsi:')));
      expect(contextStr, isNot(contains('Riwayat Ginekologis Pribadi:')));
      expect(contextStr, isNot(contains('Riwayat Penyakit Keluarga:')));
    });

    test('UserProfileData includes and handles healthProfile', () {
      final userProfile = UserProfileData(
        uid: 'user_123',
        name: 'Siti Rahma',
        email: 'siti@example.com',
        birthDate: DateTime(1998, 5, 20),
        cycleProfile: CycleProfileModel(
          trackingGoal: 'predict_period',
          lastPeriodDate: DateTime(2026, 8, 1),
          cycleLength: 28,
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(1998, 5, 20),
        ),
        healthProfile: const HealthProfileModel(
          reproductiveStatus: 'single',
          contraception: 'pill',
        ),
      );

      expect(userProfile.healthProfile, isNotNull);
      expect(userProfile.healthProfile!.contraception, 'pill');

      final copied = userProfile.copyWith(
        healthProfile: userProfile.healthProfile!.copyWith(contraception: 'none'),
      );
      expect(copied.healthProfile!.contraception, 'none');
    });

    test('ClinicalExpertSynthesizer tailors response based on PCOS in clinicalContext', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'Kenapa siklus haid saya sering tidak teratur?',
        userName: 'Siti',
        clinicalContext: 'Konteks Klinis Pengguna: Usia 24 tahun. Riwayat Ginekologis Pribadi: PCOS (Sindrom Ovarium Polikistik).',
      );

      expect(response.text, contains('Halo Kak Siti'));
      expect(response.text, contains('PCOS'));
      expect(response.text, contains('Catatan Klinis Personal:'));
    });

    test('ClinicalExpertSynthesizer tailors response based on Endometriosis in clinicalContext', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'Perut saya sakit sekali saat haid hari pertama',
        userName: 'Rina',
        clinicalContext: 'Konteks Klinis Pengguna: Usia 26 tahun. Riwayat Ginekologis Pribadi: Endometriosis.',
      );

      expect(response.text, contains('Halo Kak Rina'));
      expect(response.text, contains('endometriosis'));
      expect(response.text, contains('Catatan Klinis Personal:'));
    });
  });
}
