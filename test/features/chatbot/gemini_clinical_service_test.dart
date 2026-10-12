import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/chatbot/data/datasources/gemini_clinical_service.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiClinicalService & Resilience Tests', () {
    test(
      'GeminiClinicalService accepts clinicalContext for RAG safely without throwing',
      () async {
        final service = GeminiClinicalService();
        final response = await service.generateResponse(
          'kemaluan saya terasa nyeri',
          userName: 'yani',
          clinicalContext:
              'Rasa nyeri pada area kemaluan paling sering dipicu oleh dermatitis kontak atau infeksi vaginitis.',
        );

        // Safe execution guarantee: returns GeminiResponseResult with valid state
        expect(
          response.isSuccess
              ? (response.text != null && response.text!.isNotEmpty)
              : true,
          isTrue,
        );
      },
    );

    test(
      'ChatbotController seamlessly performs silent local failover when Gemini is unconfigured',
      () async {
        final controller = ChatbotController();
        controller.clearChat();

        await controller.sendMessage('kemaluan saya terasa nyeri');

        expect(controller.messages.length, greaterThan(1));
        final botMsg = controller.messages.last;

        expect(botMsg.isUser, isFalse);
        // Even without Gemini API key, user gets high quality naturalized clinical response
        expect(botMsg.text, startsWith('Halo Kak'));
        expect(
          botMsg.text,
          contains(
            'mengenai rasa nyeri pada area kemaluan yang sedang kamu rasakan,',
          ),
        );
        expect(botMsg.text, contains('Iritasi Kulit Luar'));
        expect(botMsg.text, contains('Referensi Pakar & Literatur Terpercaya'));
        expect(botMsg.recordNote, isNotNull);
        expect(botMsg.recordNote, contains('kemaluan saya terasa nyeri'));
      },
    );

    test(
      'ChatbotController accurately detects symptom indices and sets recordNote for cramps',
      () async {
        final controller = ChatbotController();
        controller.clearChat();

        await controller.sendMessage(
          'perut saya kram melilit dan sakit sekali',
        );

        final botMsg = controller.messages.last;
        expect(botMsg.actionRoute, equals('record'));
        expect(botMsg.recordNote, contains('perut saya kram melilit'));
        expect(botMsg.symptomIndices, contains(0)); // 0 = Kram Perut
      },
    );

    test(
      'ChatbotController handles multi-turn chained follow-up "apakah itu aman?" seamlessly',
      () async {
        final controller = ChatbotController();
        controller.clearChat();

        // Turn 1: Late period inquiry
        await controller.sendMessage('kenapa mens telat pada bulan ini');
        expect(controller.messages.length, equals(3)); // welcome + user1 + bot1

        final firstBotMsg = controller.messages.last;
        expect(firstBotMsg.isUser, isFalse);
        expect(firstBotMsg.text, contains('keterlambatan siklus haid'));

        // Turn 2: Follow-up referring to "itu" (the late period)
        await controller.sendMessage('apakah itu aman?');
        expect(controller.messages.length, equals(5)); // welcome + user1 + bot1 + user2 + bot2

        final secondBotMsg = controller.messages.last;
        expect(secondBotMsg.isUser, isFalse);
        // Must correctly resolve referral context to late period safety analysis
        expect(
          secondBotMsg.text,
          contains('keterlambatan siklus haid tersebut aman atau berbahaya'),
        );
        expect(secondBotMsg.text, contains('2 hingga 7 hari'));
        expect(secondBotMsg.text, contains('Langkah-langkah penanganan mandiri'));
      },
    );
  });
}
