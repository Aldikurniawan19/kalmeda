import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_expert_synthesizer.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_knowledge_base.dart';
import 'package:menstracker/features/chatbot/data/models/user_calendar_context.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';

void main() {
  group('ClinicalKnowledgeBase Direct Matching Tests', () {
    test('Matches common menstrual cramps query accurately', () {
      final match = ClinicalKnowledgeBase.findBestMatch(
        'kenapa perut kram saat haid',
      );
      expect(match, isNotNull);
      expect(match!.category, 'Nyeri & Kram');
      expect(match.answer, contains('prostaglandin'));
    });

    test('Matches dark blood inquiry accurately', () {
      final match = ClinicalKnowledgeBase.findBestMatch(
        'darah haid hitam cokelat pekat',
      );
      expect(match, isNotNull);
      expect(match!.category, 'Karakteristik Darah');
      expect(match.answer, contains('oksidasi'));
    });

    test('Matches cold water myth accurately', () {
      final match = ClinicalKnowledgeBase.findBestMatch(
        'apakah minum air es membekukan darah haid',
      );
      expect(match, isNotNull);
      expect(match!.category, 'Pola Hidup & Mitos');
      expect(match.answer, contains('SALAH'));
    });
  });

  group('ClinicalExpertSynthesizer In-App Semantic System Tests', () {
    test('Synthesizes physiological guidance for stabbing ovulation pain', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'perut bawah kayak ditusuk jarum pas selesai ovulasi',
      );
      expect(response.text, contains('Mittelschmerz'));
      expect(response.text, contains('Langkah Penanganan Mandiri'));
      expect(response.text, contains('Dokter Spesialis'));
      expect(response.suggestedChips, isNotEmpty);
    });

    test('Synthesizes breast tenderness guidance before period', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'kenapa payudara sebelah kiri nyeri banget sebelum haid',
      );
      expect(response.text, contains('payudara'));
      expect(response.text, contains('estrogen'));
      expect(response.suggestedChips, isNotEmpty);
    });

    test('Synthesizes herbal turmeric drink guidance on period start', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'apakah boleh minum jamu kunyit pas hari pertama haid',
      );
      expect(response.text, contains('kurkumin'));
      expect(response.text, contains('antiinflamasi'));
    });

    test('Politely handles completely off-topic non-health questions', () {
      final response = ClinicalExpertSynthesizer.synthesizeResponse(
        'bagaimana cara mengganti oli mesin mobil sport',
      );
      expect(response.text, contains('Kalmeda yang dirancang khusus'));
      expect(response.suggestedChips, isNotEmpty);
    });

    test('Guarantees zero emojis in knowledge base and synthesis output', () {
      final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
        unicode: true,
      );

      for (final entry in ClinicalKnowledgeBase.entries) {
        expect(emojiRegex.hasMatch(entry.question), isFalse);
        expect(emojiRegex.hasMatch(entry.answer), isFalse);
      }

      final testResponse = ClinicalExpertSynthesizer.synthesizeResponse(
        'kenapa perut kram dan sakit pinggang menjelang menstruasi',
      );
      expect(emojiRegex.hasMatch(testResponse.text), isFalse);
    });

    test(
      'Response contains verified clinical expert citations (Sp.OG, ACOG, POGI, Kemenkes)',
      () {
        final testResponse = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa darah haid menggumpal hitam pekat',
        );
        expect(
          testResponse.text,
          contains('Referensi Pakar & Literatur Terpercaya'),
        );
        expect(
          testResponse.text,
          contains('Dokter Spesialis Obstetri & Ginekologi (Sp.OG)'),
        );
        expect(testResponse.text, contains('POGI'));
        expect(testResponse.text, contains('ACOG'));
        expect(testResponse.text, contains('Kemenkes RI'));
      },
    );

    test(
      'Accurately matches and naturalizes "kemaluan saya terasa nyeri" without robotic filler or breast mismatch',
      () {
        final match = ClinicalKnowledgeBase.findBestMatch(
          'kemaluan saya terasa nyeri',
        );
        expect(match, isNotNull);
        expect(match!.id, 'nyeri_kemaluan_vagina');
        expect(match.question, contains('kemaluan'));

        final naturalized = ClinicalExpertSynthesizer.naturalizeDirectMatch(
          query: 'kemaluan saya terasa nyeri',
          match: match,
          userName: 'yani',
        );

        // Must capitalize name
        expect(naturalized, startsWith('Halo Kak Yani,'));
        // Must empathetically reflect specific genital problem
        expect(
          naturalized,
          contains(
            'mengenai rasa nyeri pada area kemaluan yang sedang kamu rasakan,',
          ),
        );
        // Must NOT contain robotic filler phrase
        expect(naturalized.contains('berikut penjelasannya untukmu:'), isFalse);
        // Must NOT discuss breast pain / Mastalgia
        expect(naturalized.contains('Mastalgia'), isFalse);
        expect(naturalized.contains('payudara'), isFalse);
        // Must directly explain genital causes
        expect(naturalized, contains('Iritasi Kulit Luar'));
        expect(naturalized, contains('Infeksi Vagina'));
      },
    );

    test(
      'Synthesizes natural doctor flow for custom genital pain question',
      () {
        final response = ClinicalExpertSynthesizer.synthesizeResponse(
          'kemaluan saya terasa nyeri',
          userName: 'yani',
        );

        expect(response.text, startsWith('Halo Kak Yani,'));
        expect(
          response.text,
          contains(
            'mengenai rasa nyeri pada area kemaluan yang sedang kamu rasakan,',
          ),
        );
        expect(response.text, contains('organ intim'));
        expect(response.text, contains('Langkah Penanganan Mandiri'));
        expect(response.text, contains('Jaga Area Kewanitaan Tetap Kering'));
        expect(response.text, contains('Dokter Spesialis'));
      },
    );

    test(
      'Synthesizes natural doctor flow for stabbing lower abdominal pain inquiry',
      () {
        final response = ClinicalExpertSynthesizer.synthesizeResponse(
          'Perut saya bagian bawah terasa seperti di tusuk tusuk jarum',
          userName: 'yani',
        );

        expect(response.text, startsWith('Halo Kak Yani,'));
        expect(response.text, contains('ditusuk-tusuk jarum'));
        expect(response.text, contains('Mittelschmerz'));
        expect(response.text, contains('Langkah Penanganan Mandiri'));
      },
    );

    test(
      'Dynamically adjusts greeting to any user name, multiple words, or guest fallback',
      () {
        final resDewi = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa perut kram saat haid',
          userName: 'dewi lestari',
        );
        expect(resDewi.text, startsWith('Halo Kak Dewi,'));

        final resAnnisa = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa darah haid hitam',
          userName: 'annisa',
        );
        expect(resAnnisa.text, startsWith('Halo Kak Annisa,'));

        final resGuest = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa perut kram saat haid',
          userName: '',
        );
        expect(resGuest.text, startsWith('Halo Kak,'));
      },
    );

    test(
      'Correctly populates symptom indices for back pain and other symptoms',
      () {
        final resBackPain = ClinicalExpertSynthesizer.synthesizeResponse(
          'pinggang pegal linu dan panggul sakit banget',
        );
        expect(resBackPain.symptomIndices, contains(4));

        final resAllSymptoms = ClinicalExpertSynthesizer.synthesizeResponse(
          'perut kram, kembung begah, badan lemas, pusing kepala, pinggang pegal, dan payudara nyeri',
        );
        expect(resAllSymptoms.symptomIndices, containsAll([0, 1, 2, 3, 4, 5]));
      },
    );
  });

  group('User Calendar Context Awareness Tests', () {
    test(
      'When user is late, Chatbot includes LMP, expected next period, days late, and physiological reasons',
      () {
        final refDate = DateTime(2026, 9, 5);
        final cycleProfile = CycleProfileModel(
          trackingGoal: 'track_cycle',
          lastPeriodDate: DateTime(2026, 8, 1), // 35 days ago
          cycleLength: 28, // 35 - 28 = 7 days late!
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(2000, 1, 1),
        );
        final calContext = UserCalendarContext.fromCycleProfile(
          cycleProfile: cycleProfile,
          userName: 'Siti',
          referenceDate: refDate,
        );

        expect(calContext.isLate, isTrue);
        expect(calContext.daysLate, 7);

        // Direct FAQ match test
        final match = ClinicalKnowledgeBase.findBestMatch('kenapa saya telat haid');
        expect(match, isNotNull);
        final directResponse = ClinicalExpertSynthesizer.naturalizeDirectMatch(
          query: 'kenapa saya telat haid',
          match: match!,
          userName: 'Siti',
          calendarContext: calContext,
        );

        expect(directResponse, contains('Halo Kak Siti,'));
        expect(directResponse, contains('Melihat Kalender Siklus Pribadimu:'));
        expect(directResponse, contains('terlambat 7 hari'));
        expect(directResponse, contains('28 hari'));
        expect(directResponse.toLowerCase(), contains('kortisol'));
        expect(directResponse, contains('test pack'));
        expect(directResponse, contains('Sp.OG'));
        expect(directResponse, contains('Referensi Pakar & Literatur Terpercaya'));

        // Custom arbitrary inquiry test
        final customResponse = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa saya belum haid ya padahal sudah telat',
          userName: 'Siti',
          calendarContext: calContext,
        );

        expect(customResponse.text, contains('Halo Kak Siti,'));
        expect(customResponse.text, contains('Melihat Kalender Siklus Pribadimu:'));
        expect(customResponse.text, contains('terlambat 7 hari'));
        expect(customResponse.text, contains('28 hari'));
        expect(customResponse.text, contains('test pack'));
        expect(customResponse.text, contains('Sp.OG'));
      },
    );

    test(
      'When user is NOT late, Chatbot references calendar showing cycle day and remaining days',
      () {
        final refDate = DateTime(2026, 9, 5);
        final cycleProfile = CycleProfileModel(
          trackingGoal: 'track_cycle',
          lastPeriodDate: DateTime(2026, 8, 25), // 11 days ago
          cycleLength: 28,
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(2000, 1, 1),
        );
        final calContext = UserCalendarContext.fromCycleProfile(
          cycleProfile: cycleProfile,
          userName: 'Nadia',
          referenceDate: refDate,
        );

        expect(calContext.isLate, isFalse);
        expect(calContext.currentCycleDay, 12);

        final response = ClinicalExpertSynthesizer.synthesizeResponse(
          'kenapa saya belum haid juga ya',
          userName: 'Nadia',
          calendarContext: calContext,
        );

        expect(response.text, contains('Melihat Kalender Siklus Pribadimu:'));
        expect(response.text, contains('hari ke-12'));
        expect(response.text, contains('belum terlambat'));
      },
    );

    test(
      'When user asks about normal cycle, Chatbot provides medical range AND personal calendar history',
      () {
        final refDate = DateTime(2026, 9, 5);
        final cycleProfile = CycleProfileModel(
          trackingGoal: 'track_cycle',
          lastPeriodDate: DateTime(2026, 8, 15),
          cycleLength: 28,
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(2000, 1, 1),
        );
        final calContext = UserCalendarContext.fromCycleProfile(
          cycleProfile: cycleProfile,
          userName: 'Rina',
          referenceDate: refDate,
        );

        // Direct match test
        final match = ClinicalKnowledgeBase.findBestMatch('berapa hari rentang siklus normal');
        expect(match, isNotNull);
        final directResp = ClinicalExpertSynthesizer.naturalizeDirectMatch(
          query: 'berapa hari rentang siklus normal',
          match: match!,
          userName: 'Rina',
          calendarContext: calContext,
        );

        expect(directResp, contains('21 hingga 35 hari'));
        expect(directResp, contains('3 hingga 7 hari'));
        expect(directResp, contains('Melihat Riwayat Kalender Siklus Pribadimu:'));
        expect(directResp, contains('28 hari'));
        expect(directResp, contains('5 hari'));
        expect(directResp, contains('rentang standar medis yang sangat baik'));

        // Custom phrasing inquiry test
        final customResp = ClinicalExpertSynthesizer.synthesizeResponse(
          'apakah siklus haid saya normal',
          userName: 'Rina',
          calendarContext: calContext,
        );

        expect(customResp.text, contains('21 hingga 35 hari'));
        expect(customResp.text, contains('Melihat Riwayat Kalender Siklus Pribadimu:'));
        expect(customResp.text, contains('28 hari'));
      },
    );

    test(
      'When user asks about next period date, Chatbot returns exact predicted calendar date',
      () {
        final refDate = DateTime(2026, 9, 5);
        final cycleProfile = CycleProfileModel(
          trackingGoal: 'track_cycle',
          lastPeriodDate: DateTime(2026, 8, 15),
          cycleLength: 28,
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(2000, 1, 1),
        );
        final calContext = UserCalendarContext.fromCycleProfile(
          cycleProfile: cycleProfile,
          userName: 'Rina',
          referenceDate: refDate,
        );

        final response = ClinicalExpertSynthesizer.synthesizeResponse(
          'kapan saya haid lagi ya',
          userName: 'Rina',
          calendarContext: calContext,
        );

        expect(response.text, contains('Berdasarkan Kalender Siklus Pribadimu:'));
        expect(response.text, contains('Perkiraan Haid Berikutnya'));
        expect(response.text, contains('28 hari'));
      },
    );

    test(
      'When user asks about fertile window, Chatbot returns calculated fertile window and peak ovulation',
      () {
        final refDate = DateTime(2026, 9, 5);
        final cycleProfile = CycleProfileModel(
          trackingGoal: 'track_cycle',
          lastPeriodDate: DateTime(2026, 9, 1),
          cycleLength: 28,
          periodDuration: 5,
          regularity: 'regular',
          birthDate: DateTime(2000, 1, 1),
        );
        final calContext = UserCalendarContext.fromCycleProfile(
          cycleProfile: cycleProfile,
          userName: 'Rina',
          referenceDate: refDate,
        );

        final response = ClinicalExpertSynthesizer.synthesizeResponse(
          'kapan masa subur saya',
          userName: 'Rina',
          calendarContext: calContext,
        );

        expect(response.text, contains('Melihat Kalender Kesuburan Pribadimu:'));
        expect(response.text, contains('Perkiraan Puncak Ovulasi:'));
        expect(response.text, contains('Jendela Masa Subur:'));
      },
    );
  });
}
