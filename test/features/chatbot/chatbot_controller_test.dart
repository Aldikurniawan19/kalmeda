import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatbotController Tests', () {
    late ChatbotController controller;

    setUp(() {
      controller = ChatbotController();
      controller.clearChat();
    });

    test(
      'Initializes with authoritative medical references and auto-clear privacy notice',
      () {
        expect(controller.messages, hasLength(1));
        final welcome = controller.messages.first;
        expect(welcome.isUser, isFalse);
        expect(
          welcome.text,
          contains('Dokter Spesialis Obstetri & Ginekologi (Sp.OG)'),
        );
        expect(welcome.text, contains('POGI'));
        expect(welcome.text, contains('ACOG'));
        expect(welcome.text, contains('Kemenkes RI'));
        expect(
          welcome.text,
          contains('otomatis terhapus begitu Anda keluar dari aplikasi'),
        );
      },
    );

    test(
      'clearChat resets messages and purges conversation on app exit',
      () async {
        await controller.sendMessage('kenapa darah haid hitam');
        expect(controller.messages.length, greaterThan(1));

        // Simulate app exit event triggering clearChat
        controller.clearChat();

        expect(controller.messages, hasLength(1));
        expect(controller.messages.first.id, 'welcome_msg');
        expect(controller.isTyping, isFalse);
        expect(controller.selectedCategory, 'Semua');
      },
    );

    test(
      'Direct match response includes authoritative clinical references',
      () async {
        await controller.sendMessage('kenapa perut kram saat haid');
        final botMessage = controller.messages.last;

        expect(botMessage.isUser, isFalse);
        expect(
          botMessage.text,
          contains('Referensi Pakar & Literatur Terpercaya'),
        );
        expect(
          botMessage.text,
          contains('dokter spesialis obstetri & ginekologi (Sp.OG)'),
        );
        expect(botMessage.text, contains('ACOG'));
        expect(botMessage.text, contains('Kemenkes RI'));
      },
    );

    test(
      'End-to-end "kemaluan saya terasa nyeri" returns naturalized genital guidance',
      () async {
        await controller.sendMessage('kemaluan saya terasa nyeri');
        final botMessage = controller.messages.last;

        expect(botMessage.isUser, isFalse);
        expect(
          botMessage.text,
          contains(
            'mengenai rasa nyeri pada area kemaluan yang sedang kamu rasakan,',
          ),
        );
        expect(botMessage.text.contains('Mastalgia'), isFalse);
        expect(botMessage.text.contains('payudara'), isFalse);
        expect(botMessage.text, contains('Iritasi Kulit Luar'));
        expect(
          botMessage.text,
          contains('Referensi Pakar & Literatur Terpercaya'),
        );
      },
    );
  });
}
