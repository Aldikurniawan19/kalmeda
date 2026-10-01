import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_knowledge_base.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_bubble.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/typing_indicator.dart';
import 'package:menstracker/features/record/presentation/controllers/record_draft_service.dart';
import 'package:menstracker/features/record/presentation/screens/record_screen.dart';

/// Full-screen interactive clinical consultation chatbot screen for Kalmeda.
/// Features authentic WhatsApp-inspired chat aesthetics (bubbles, pills, wallpaper, encryption banner),
/// automatic chat clearance on app exit for medical privacy, and verified clinical expert citations.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatbotScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ChatbotScreen({super.key, this.onNavigateTab});

  static Future<void> open(
    BuildContext context, {
    ValueChanged<int>? onNavigateTab,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(onNavigateTab: onNavigateTab),
      ),
    );
  }

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = ChatbotController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  GlobalKey? _latestUserMessageKey;
  bool _showScrollToBottom = false;
  bool _hasUnreadBelow = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _prevMessageCount = _controller.messages.length;
    _controller.addListener(_onControllerUpdated);
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isScrolledUp = (maxScroll - currentScroll) > 120;

    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
        if (!isScrolledUp) {
          _hasUnreadBelow = false;
        }
      });
    }
  }

  void _onControllerUpdated() {
    final currentCount = _controller.messages.length;
    final isNewMessage = currentCount > _prevMessageCount;
    _prevMessageCount = currentCount;

    if (isNewMessage && _controller.messages.isNotEmpty) {
      final latest = _controller.messages.last;
      if (latest.isUser) {
        // User sent message: keep bubble at top with comfortable margin
        _scrollToLatestUserMessage();
      } else {
        // Bot replied!
        if (_showScrollToBottom) {
          // If user scrolled up to read past history, notify with unread dot
          setState(() {
            _hasUnreadBelow = true;
          });
        } else {
          // Keep user question visible at top, answer flows below it naturally
          _anchorToLatestUserMessage();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScrollChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToLatestUserMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _latestUserMessageKey?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment:
              0.02, // Align to top of viewport with comfortable breathing room
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _anchorToLatestUserMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _latestUserMessageKey?.currentContext;
      if (ctx != null && ctx.mounted) {
        // Re-anchor user question at the top so bot answer begins right beneath it
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.02,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        setState(() {
          _hasUnreadBelow = false;
        });
      }
    });
  }

  void _handleSend() {
    final query = _textController.text;
    if (query.trim().isEmpty) return;

    _textController.clear();
    _latestUserMessageKey = GlobalKey();
    _controller.sendMessage(query);
  }

  void _handleChipTapped(String chip) {
    _latestUserMessageKey = GlobalKey();
    _controller.sendPromptChip(chip);
  }

  void _handleAction(String route, {ChatMessageModel? message}) {
    if (route == 'record') {
      final note =
          message?.recordNote ??
          (message != null && !message.isUser
              ? 'Keluhan dari Konsultasi Medis'
              : 'Keluhan dari Konsultasi');
      final symptoms = message?.symptomIndices != null
          ? Set<int>.from(message!.symptomIndices!)
          : <int>{};

      RecordDraftService().setDraft(note: note, symptoms: symptoms);

      Navigator.of(context).pop();
      if (widget.onNavigateTab != null) {
        widget.onNavigateTab!(2);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                RecordScreen(initialNotes: note, initialSymptoms: symptoms),
          ),
        );
      }
    } else if (route == 'calendar') {
      Navigator.of(context).pop();
      if (widget.onNavigateTab != null) {
        widget.onNavigateTab!(1);
      }
    }
  }

  void _handleQuickRecord() {
    final candidate = _controller.messages.reversed.firstWhere(
      (m) =>
          m.recordNote != null ||
          (m.symptomIndices != null && m.symptomIndices!.isNotEmpty),
      orElse: () => _controller.messages.reversed.firstWhere(
        (m) => m.isUser,
        orElse: () => _controller.messages.first,
      ),
    );

    final note =
        candidate.recordNote ??
        (candidate.isUser
            ? 'Keluhan Konsultasi: ${candidate.text}'
            : 'Keluhan dari Konsultasi Medis');
    final symptoms = candidate.symptomIndices != null
        ? Set<int>.from(candidate.symptomIndices!)
        : <int>{};

    RecordDraftService().setDraft(note: note, symptoms: symptoms);
    Navigator.of(context).pop();

    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(2);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RecordScreen(initialNotes: note, initialSymptoms: symptoms),
        ),
      );
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Hapus Chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Hapus seluruh riwayat percakapan sesi ini? Pesan Anda juga otomatis terhapus saat Anda keluar dari aplikasi.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _latestUserMessageKey = null;
              _showScrollToBottom = false;
              _hasUnreadBelow = false;
              _controller.clearChat();
              _prevMessageCount = _controller.messages.length;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat percakapan telah dihapus.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showExpertiseInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dasar Klinis & Kepakaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Standar Medis & Literatur Terpercaya:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '1. Dokter Spesialis Obstetri & Ginekologi (Sp.OG)\nSeluruh materi klinis dan sintesis gejala ditinjau berdasarkan pedoman resmi dokter spesialis kandungan.\n\n2. Konsensus Resmi POGI & Kemenkes RI\nMerujuk pada Panduan Praktik Klinis Perkumpulan Obstetri dan Ginekologi Indonesia dan Standar Pelayanan Medis Kemenkes RI.\n\n3. Standar Emas ACOG & WHO\nDiselaraskan dengan pedoman American College of Obstetricians and Gynecologists dan World Health Organization.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 12),
              Divider(height: 1, color: AppColors.cardBorder),
              SizedBox(height: 12),
              Text(
                'Jaminan Privasi Medis & Kerahasiaan:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Riwayat percakapan disimpan secara sementara di memori internal dan akan otomatis terhapus secara menyeluruh begitu Anda keluar dari aplikasi. Data tidak dikirim ke server pihak ketiga.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatScaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.chatAppBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.cardBorder),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.chatOnlineIndicator,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.chatAppBarBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Konsultan Medis Kalmeda',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Online • Terverifikasi Sp.OG & Kemenkes',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Catat Keluhan ke Jurnal',
            icon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: _handleQuickRecord,
          ),
          IconButton(
            tooltip: 'Hapus Percakapan',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: _confirmClearChat,
          ),
          IconButton(
            tooltip: 'Dasar Klinis & Kepakaran',
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: _showExpertiseInfoDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category filter chips
            Container(
              height: 46,
              color: AppColors.cardBackground,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space12,
                      vertical: 6,
                    ),
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: ClinicalKnowledgeBase.categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = ClinicalKnowledgeBase.categories[index];
                      final isSelected = _controller.selectedCategory == cat;

                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          _controller.setCategory(cat);
                          _scrollToBottom();
                        },
                        backgroundColor: AppColors.chatChipBackground,
                        selectedColor: AppColors.primary,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.chatChipBorder,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Chat Messages list & WhatsApp Floating Scroll Button
            Expanded(
              child: Stack(
                children: [
                  SelectionArea(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final messages = _controller.messages;
                        final isTyping = _controller.isTyping;
                        final latestUserId = _controller.latestUserMessageId;

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          itemCount: messages.length + (isTyping ? 1 : 0) + 2,
                          itemBuilder: (context, index) {
                            // 1. Top Privacy & Clinical Reassurance Notice
                            if (index == 0) {
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                  left: 16,
                                  right: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.chatNoticeBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.chatNoticeBorder,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.lock_rounded,
                                          size: 13,
                                          color: AppColors.chatNoticeTitle,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Kerahasiaan Medis & Privasi Terjaga',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.chatNoticeTitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Pesan bersifat privat & sementara. Chat akan otomatis terhapus saat Anda keluar dari aplikasi. Seluruh informasi disintesis dari referensi klinis resmi dokter spesialis obstetri & ginekologi (Sp.OG), ACOG, POGI, dan Standar Pelayanan Medis Kemenkes RI.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        height: 1.35,
                                        color: AppColors.chatNoticeText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // 2. Date Capsule
                            if (index == 1) {
                              return Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x06000000),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'HARI INI',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final msgIndex = index - 2;
                            if (msgIndex == messages.length && isTyping) {
                              return const TypingIndicator();
                            }

                            final msg = messages[msgIndex];
                            final isLatestUser =
                                msg.isUser && msg.id == latestUserId;

                            return Container(
                              key: isLatestUser
                                  ? _latestUserMessageKey
                                  : ValueKey(msg.id),
                              child: ChatBubble(
                                message: msg,
                                onChipTapped: _handleChipTapped,
                                onActionTapped: (route, message) =>
                                    _handleAction(route, message: message),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // WhatsApp-inspired Floating Scroll-to-Bottom Button
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: AnimatedScale(
                      scale: _showScrollToBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: _showScrollToBottom ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _scrollToBottom,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cardBorder,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textSecondary,
                                    size: 24,
                                  ),
                                  if (_hasUnreadBelow)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input Bar at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Input Pill
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12, right: 6),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  focusNode: _focusNode,
                                  minLines: 1,
                                  maxLines: 4,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Ketik keluhan atau pertanyaan kesehatan...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _handleSend(),
                                ),
                              ),
                              if (_textController.text.trim().isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => _textController.clear(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Floating Circular Send Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 19,
                            color: AppColors.textWhite,
                          ),
                          onPressed: _handleSend,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ditinjau oleh Tim Dokter Spesialis Sp.OG • Standar ACOG & Kemenkes RI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
