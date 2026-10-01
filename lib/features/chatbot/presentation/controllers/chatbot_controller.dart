import 'package:flutter/material.dart';

import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_expert_synthesizer.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_knowledge_base.dart';
import 'package:menstracker/features/chatbot/data/datasources/gemini_clinical_service.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';
import 'package:menstracker/features/chatbot/data/models/faq_knowledge_model.dart';
import 'package:menstracker/features/chatbot/data/models/user_calendar_context.dart';
import 'package:menstracker/features/profile/data/repositories/profile_repository_impl.dart';

/// Controller managing chatbot conversational state, typing animation state,
/// AI clinical consultation with 60-second resilience timeout and seamless local expert fallback.
class ChatbotController extends ChangeNotifier {
  static final ChatbotController _instance = ChatbotController._internal();
  factory ChatbotController() => _instance;

  ChatbotController._internal() {
    _initWelcomingMessage();
  }

  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _selectedCategory = 'Semua';
  String? _latestUserMessageId;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get selectedCategory => _selectedCategory;
  String? get latestUserMessageId => _latestUserMessageId;

  void _initWelcomingMessage() {
    _messages.clear();
    _latestUserMessageId = null;
    _messages.add(
      ChatMessageModel(
        id: 'welcome_msg',
        text:
            'Halo! Saya **Konsultan Klinis Kalmeda**.\n\n'
            '**Setiap arahan medis yang Anda terima disarikan langsung dari referensi medis terpercaya berstandar emas:**\n'
            '• **Ditinjau Pedoman Dokter Spesialis Obstetri & Ginekologi (Sp.OG)**\n'
            '• **Panduan Praktik Klinis Perkumpulan Obstetri & Ginekologi Indonesia (POGI)**\n'
            '• **Standar Pelayanan Medis Kesehatan Reproduksi Kemenkes RI**\n'
            '• **Rekomendasi American College of Obstetricians and Gynecologists (ACOG) & WHO**\n\n'
            'Informasi ini disusun secara ilmiah untuk memberikan panduan yang akurat, aman, dan menenangkan. Sesi konsultasi ini bersifat privat dan seluruh riwayat chat akan otomatis terhapus begitu Anda keluar dari aplikasi.\n\n'
            'Silakan tanyakan keluhan Anda atau pilih topik konsultasi di bawah ini.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedChips: const [
          'Berapa hari rentang siklus normal?',
          'Cara meredakan kram perut tanpa obat',
          'Kenapa darah haid berwarna hitam?',
          'Kapan masa subur (ovulasi) terjadi?',
          'Perbedaan keputihan normal vs tanda infeksi',
          'Mitos minum air es saat menstruasi',
        ],
      ),
    );
  }

  /// Clears consultation history, resets typing and category state, and restores initial welcoming prompt.
  void clearChat() {
    _isTyping = false;
    _selectedCategory = 'Semua';
    _latestUserMessageId = null;
    _initWelcomingMessage();
    notifyListeners();
  }

  /// Sends a user question, queries AI service first with 60s timeout,
  /// and gracefully falls back to verified clinical expert engine if needed.
  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    // 1. Append user message
    final userMsgId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    _latestUserMessageId = userMsgId;
    _messages.add(
      ChatMessageModel(
        id: userMsgId,
        text: clean,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _isTyping = true;
    notifyListeners();

    // Retrieve user's name if authenticated
    String? userName;
    try {
      final user = AuthController().currentUser;
      if (user != null && user.name.trim().isNotEmpty) {
        userName = user.name.trim().split(' ').first;
      }
    } catch (_) {}

    // Retrieve clinical profile context (cycle + health) & real-time calendar context
    String? clinicalContext;
    UserCalendarContext? calendarContext;
    try {
      final userProfile = await ProfileRepositoryImpl().getUserProfile();
      calendarContext = UserCalendarContext.fromUserProfile(userProfile: userProfile);
      final hp = userProfile.healthProfile;
      final cp = userProfile.cycleProfile;
      final age = DateTime.now().year - userProfile.birthDate.year;

      final buffer = StringBuffer();
      buffer.writeln(calendarContext.toPromptContext());
      if (hp != null) {
        buffer.writeln();
        buffer.writeln(
          hp.toClinicalContextString(
            age: age,
            cycleLength: cp.cycleLength,
            periodDuration: cp.periodDuration,
            regularity: cp.regularity,
          ),
        );
      }
      clinicalContext = buffer.toString().trim();
    } catch (_) {}

    final directMatch = ClinicalKnowledgeBase.findBestMatch(clean);
    final detectedSymptoms = detectSymptomIndices(clean);
    final recordNote = 'Keluhan Konsultasi: $clean';

    // 2. Primary: Request AI response with 60-second resilience window
    GeminiResponseResult? aiResult;
    try {
      aiResult = await GeminiClinicalService()
          .generateResponse(
            clean,
            userName: userName,
            clinicalContext: clinicalContext,
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      aiResult = null;
    }

    // 3. If AI responds successfully, deliver the AI clinical answer
    if (aiResult != null &&
        aiResult.isSuccess &&
        aiResult.text != null &&
        aiResult.text!.trim().isNotEmpty) {
      _messages.add(
        ChatMessageModel(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          text: aiResult.text!.trim(),
          isUser: false,
          timestamp: DateTime.now(),
          suggestedChips:
              directMatch?.relatedChips ??
              const [
                'Berapa hari rentang siklus normal?',
                'Cara meredakan kram perut tanpa obat',
                'Kapan masa subur (ovulasi) terjadi?',
              ],
          actionRoute: 'record',
          actionLabel: 'Catat Keluhan Ini di Menu Catat',
          recordNote: recordNote,
          symptomIndices: detectedSymptoms,
        ),
      );
      _isTyping = false;
      notifyListeners();
      return;
    }

    // 4. Fallback: If AI fails or exceeds 60 seconds, seamlessly transition to verified local clinical engine
    if (directMatch != null) {
      final answerText = ClinicalExpertSynthesizer.naturalizeDirectMatch(
        query: clean,
        match: directMatch,
        userName: userName,
        calendarContext: calendarContext,
      );

      _messages.add(
        ChatMessageModel(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          text: answerText,
          isUser: false,
          timestamp: DateTime.now(),
          suggestedChips: directMatch.relatedChips,
          actionRoute: directMatch.actionRoute,
          actionLabel: directMatch.actionLabel,
          recordNote: directMatch.actionRoute == 'record' ? recordNote : null,
          symptomIndices: detectedSymptoms,
        ),
      );
    } else {
      final synthesized = ClinicalExpertSynthesizer.synthesizeResponse(
        clean,
        userName: userName,
        clinicalContext: clinicalContext,
        calendarContext: calendarContext,
      );
      _messages.add(synthesized);
    }

    _isTyping = false;
    notifyListeners();
  }

  /// Sends a preselected prompt chip.
  void sendPromptChip(String prompt) {
    sendMessage(prompt);
  }

  /// Sets selected category filter and displays sample questions.
  void setCategory(String category) {
    _selectedCategory = category;

    List<FaqKnowledgeModel> categoryEntries;
    if (category == 'Semua') {
      categoryEntries = ClinicalKnowledgeBase.entries.take(4).toList();
    } else {
      categoryEntries = ClinicalKnowledgeBase.entries
          .where((e) => e.category == category)
          .take(4)
          .toList();
    }

    final chips = categoryEntries.map((e) => e.question).toList();

    _messages.add(
      ChatMessageModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Topik $category: Berikut beberapa pertanyaan yang sering dikonsultasikan:',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedChips: chips,
      ),
    );

    notifyListeners();
  }

  /// Helper mapping consultation text keywords to symptom selector indices in RecordScreen.
  static List<int> detectSymptomIndices(String text) {
    final lower = text.toLowerCase();
    final list = <int>{};
    if (lower.contains('kram') ||
        lower.contains('melilit') ||
        lower.contains('sakit perut') ||
        lower.contains('mules') ||
        lower.contains('nyeri haid') ||
        lower.contains('dismenore')) {
      list.add(0); // Kram Perut
    }
    if (lower.contains('kembung') ||
        lower.contains('begah') ||
        lower.contains('gas')) {
      list.add(1); // Kembung
    }
    if (lower.contains('lelah') ||
        lower.contains('capek') ||
        lower.contains('lemas') ||
        lower.contains('letih') ||
        lower.contains('lesu')) {
      list.add(2); // Kelelahan
    }
    if (lower.contains('kepala') ||
        lower.contains('pusing') ||
        lower.contains('migrain') ||
        lower.contains('pening')) {
      list.add(3); // Sakit Kepala
    }
    if (lower.contains('pinggang') ||
        lower.contains('punggung') ||
        lower.contains('pegal') ||
        lower.contains('pegel') ||
        lower.contains('ngilu')) {
      list.add(4); // Sakit Pinggang
    }
    if (lower.contains('payudara') ||
        lower.contains('dada') ||
        lower.contains('mastalgia')) {
      list.add(5); // Payudara Nyeri
    }
    if (lower.contains('jerawat') ||
        lower.contains('bruntusan') ||
        lower.contains('kulit berminyak')) {
      list.add(6); // Jerawat
    }
    if (lower.contains('makan') ||
        lower.contains('ngidam') ||
        lower.contains('lapar')) {
      list.add(7); // Nafsu Makan
    }
    return list.toList();
  }
}
