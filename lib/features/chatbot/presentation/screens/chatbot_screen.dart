import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/data/datasources/clinical_knowledge_base.dart';
import 'package:menstracker/features/chatbot/data/datasources/voice_recording_service.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chat_mascot_controller.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_bubble.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_input_bar.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot_greeting_overlay.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot_thinking_overlay.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot_wandering_overlay.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_message_entrance.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_voice_note_overlay.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/typing_indicator.dart';
import 'package:menstracker/features/record/presentation/controllers/record_draft_service.dart';
import 'package:menstracker/features/record/presentation/screens/record_screen.dart';

/// Full-screen interactive clinical consultation chatbot screen for Kalmeda.
/// Features authentic WhatsApp-inspired chat aesthetics (bubbles, pills, wallpaper, encryption banner),
/// automatic chat clearance on app exit for medical privacy, and verified clinical expert citations.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatbotScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final Offset? initialFabPosition;

  const ChatbotScreen({super.key, this.onNavigateTab, this.initialFabPosition});

  static Future<void> open(
    BuildContext context, {
    ValueChanged<int>? onNavigateTab,
    Offset? initialFabPosition,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatbotScreen(
            onNavigateTab: onNavigateTab,
            initialFabPosition: initialFabPosition,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  /// Inactivity threshold before the mascot wakes up to offer interactive assistance.
  static const Duration _idleWanderThreshold = Duration(seconds: 30);

  final _controller = ChatbotController();
  final _mascotController = ChatMascotController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// Message ids already rendered, so the entrance animation plays only once.
  final Set<String> _seenMessageIds = {};

  GlobalKey? _latestUserMessageKey;
  final GlobalKey _appBarAvatarKey = GlobalKey();
  bool _showScrollToBottom = false;
  bool _hasUnreadBelow = false;
  bool _showGreetingOverlay = true;
  bool _showThinkingOverlay = false;
  bool _showWanderingOverlay = false;
  bool _isRecordingVoiceNote = false;
  bool _isProcessingVoiceNote = false;
  double _voiceNoteDragOffset = 0.0;
  DateTime? _voiceRecordStartTime;
  bool _isDismissingWander = false;
  bool _isWakingUp = false;
  Offset? _lastWanderPosition;
  Offset? _thinkingStartPos;
  Timer? _idleWanderTimer;
  int _prevMessageCount = 0;

  late final AnimationController _anticipationController;

  @override
  void initState() {
    super.initState();
    _anticipationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _prevMessageCount = _controller.messages.length;
    _seenMessageIds.addAll(_controller.messages.map((m) => m.id));
    _controller.addListener(_onControllerUpdated);
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollChanged);
    _focusNode.addListener(_syncMascotInput);
    _mascotController.setGenerating(_controller.isTyping);
    _mascotController.greet();
    // Pre-initialize voice recording service & permissions to eliminate any start delay
    VoiceRecordingService().initialize();
  }

  void _resetIdleTimer() {
    _idleWanderTimer?.cancel();
    if (_isWakingUp) {
      _anticipationController.stop();
      _isWakingUp = false;
      _mascotController.setAnticipating(false);
    }
    if (_showGreetingOverlay ||
        _showThinkingOverlay ||
        _controller.isTyping ||
        _isRecordingVoiceNote) {
      return;
    }
    _idleWanderTimer = Timer(_idleWanderThreshold, () {
      if (!mounted) return;
      if (!_showGreetingOverlay &&
          !_showThinkingOverlay &&
          !_controller.isTyping &&
          !_showWanderingOverlay &&
          !_isWakingUp) {
        setState(() {
          _isWakingUp = true;
        });
        _mascotController.setAnticipating(true);
        _anticipationController.forward(from: 0.0).then((_) {
          if (mounted && _isWakingUp) {
            _mascotController.setAnticipating(false);
            setState(() {
              _isWakingUp = false;
              _showWanderingOverlay = true;
              _isDismissingWander = false;
            });
          }
        });
      }
    });
  }

  void _onTextChanged() {
    setState(() {});
    _syncMascotInput();
    if (!_showWanderingOverlay) {
      _resetIdleTimer();
    }
  }

  void _syncMascotInput() {
    _mascotController.updateInput(
      hasFocus: _focusNode.hasFocus,
      text: _textController.text,
    );
    if (!_showWanderingOverlay) {
      _resetIdleTimer();
    }
  }

  void _onScrollChanged() {
    if (!_showWanderingOverlay) {
      _resetIdleTimer();
    }
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
    _mascotController.setGenerating(_controller.isTyping);

    if (_controller.isTyping) {
      // Smoothly morph wandering mascot directly into the thinking popup
      final startPos = _showWanderingOverlay ? _lastWanderPosition : null;
      _showWanderingOverlay = false;
      _isDismissingWander = false;

      if (!_showGreetingOverlay && !_showThinkingOverlay) {
        setState(() {
          _thinkingStartPos = startPos;
          _showThinkingOverlay = true;
        });
      }
    }

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
        _mascotController.celebrateAnswer();
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

    _resetIdleTimer();
  }

  void _toggleMascotInteractive() {
    _mascotController.registerTap();

    if (_mascotController.isAngry) {
      // Mascot is angry: dismiss wandering overlay if active so angry mood shows on AppBar
      if (_showWanderingOverlay) {
        setState(() {
          _isDismissingWander = true;
        });
      }
      return;
    }

    if (_controller.isTyping ||
        _showThinkingOverlay ||
        _showGreetingOverlay ||
        _isRecordingVoiceNote) {
      return;
    }

    if (_isWakingUp) {
      _idleWanderTimer?.cancel();
      _anticipationController.stop();
      _mascotController.setAnticipating(false);
      setState(() {
        _isWakingUp = false;
        _showWanderingOverlay = true;
        _isDismissingWander = false;
      });
      return;
    }

    if (_showWanderingOverlay) {
      // If already roaming, swoop smoothly back to AppBar
      setState(() {
        _isDismissingWander = true;
      });
    } else {
      // Swoop out from AppBar avatar into the chat screen
      _idleWanderTimer?.cancel();
      setState(() {
        _showWanderingOverlay = true;
        _isDismissingWander = false;
      });
    }
  }

  @override
  void dispose() {
    _idleWanderTimer?.cancel();
    _anticipationController.dispose();
    _controller.removeListener(_onControllerUpdated);
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScrollChanged);
    _focusNode.removeListener(_syncMascotInput);
    _mascotController.dispose();
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
              _showGreetingOverlay = true;
              _showThinkingOverlay = false;
              _isProcessingVoiceNote = false;
              _controller.clearChat();
              _prevMessageCount = _controller.messages.length;
              _seenMessageIds.clear();
              _mascotController.greet();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat percakapan telah dihapus.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(context),
                _buildCategoryChips(),
                const Divider(height: 1, color: AppColors.cardBorder),
                Expanded(
                  child: Stack(
                    children: [
                      SelectionArea(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => _buildMessagesList(),
                        ),
                      ),
                      _buildScrollToBottomButton(),

                      // Active Voice Note Recording Overlay (Frosted glass blur + centered listening mascot)
                      if (_isRecordingVoiceNote)
                        ChatVoiceNoteOverlay(
                          dragOffset: _voiceNoteDragOffset,
                          isCancelThresholdMet: _voiceNoteDragOffset < -65,
                          onCancel: () {
                            if (mounted) {
                              setState(() {
                                _isRecordingVoiceNote = false;
                                _voiceNoteDragOffset = 0.0;
                              });
                              _resetIdleTimer();
                            }
                          },
                          onSendVoiceNote: (durationSeconds) {
                            if (mounted) {
                              setState(() {
                                _isRecordingVoiceNote = false;
                                _voiceNoteDragOffset = 0.0;
                              });
                              _latestUserMessageKey = GlobalKey();
                              _controller.sendVoiceNote(
                                durationSeconds: durationSeconds,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                ChatInputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  onSend: _handleSend,
                  onVoiceRecordStart: () {
                    // Close wandering overlay if active and open Voice Note recording
                    if (_showWanderingOverlay) {
                      _showWanderingOverlay = false;
                      _isDismissingWander = false;
                    }
                    _idleWanderTimer?.cancel();
                    setState(() {
                      _isRecordingVoiceNote = true;
                      _voiceNoteDragOffset = 0.0;
                      _voiceRecordStartTime = DateTime.now();
                    });
                    // Start actual microphone speech recognition and audio recording
                    VoiceRecordingService().startRecording();
                  },
                  onVoiceRecordDrag: (deltaX) {
                    if (_isRecordingVoiceNote) {
                      setState(() {
                        _voiceNoteDragOffset = deltaX;
                      });
                    }
                  },
                  onVoiceRecordEnd: (isCancelled) async {
                    if (!_isRecordingVoiceNote) return;
                    final startTime = _voiceRecordStartTime ?? DateTime.now();
                    final duration = DateTime.now().difference(startTime);
                    final durationSeconds = math.max(1, duration.inSeconds);

                    setState(() {
                      _isRecordingVoiceNote = false;
                      _voiceNoteDragOffset = 0.0;
                    });
                    _resetIdleTimer();

                    if (isCancelled) {
                      await VoiceRecordingService().cancelRecording();
                    } else {
                      _latestUserMessageKey = GlobalKey();
                      setState(() {
                        _isProcessingVoiceNote = true;
                      });

                      // Retrieve live speech recognition words and audio bytes
                      final recordResult = await VoiceRecordingService().stopRecording(
                        isCancelled: false,
                      );

                      _controller
                          .sendVoiceNote(
                            durationSeconds: durationSeconds,
                            transcribedText: recordResult.transcribedText,
                            base64Audio: recordResult.base64Audio,
                            mimeType: recordResult.mimeType,
                          )
                          .then((_) {
                        if (mounted) {
                          setState(() {
                            _isProcessingVoiceNote = false;
                          });
                        }
                      });
                    }
                  },
                  onVoiceNoteTapHint: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tahan tombol mikrofon untuk merekam suara, lalu lepas untuk mengirim.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  isGenerating: _controller.isTyping,
                  isRecordingVoice: _isRecordingVoiceNote,
                  isCancelThresholdMet: _voiceNoteDragOffset < -65,
                ),
              ],
            ),

            // Centered Floating Mascot Greeting Popup Overlay with Coucou Return-Flight
            if (_showGreetingOverlay)
              ChatMascotGreetingOverlay(
                initialFabPosition: widget.initialFabPosition,
                targetAvatarGlobalKey: _appBarAvatarKey,
                onDismissed: () {
                  if (mounted) {
                    setState(() {
                      _showGreetingOverlay = false;
                    });
                    _resetIdleTimer();
                  }
                },
              ),

            // Centered Floating Thinking Mascot Overlay (Mascot Only, No Thought Bubble)
            if (!_showGreetingOverlay && _showThinkingOverlay)
              ChatMascotThinkingOverlay(
                isGenerating: _controller.isTyping,
                isVoiceNote: _isProcessingVoiceNote,
                targetAvatarGlobalKey: _appBarAvatarKey,
                initialPositionInOverlay: _thinkingStartPos,
                onDismissed: () {
                  if (mounted) {
                    setState(() {
                      _showThinkingOverlay = false;
                      _thinkingStartPos = null;
                      _lastWanderPosition = null;
                    });
                    _resetIdleTimer();
                  }
                },
              ),

            // Floating Interactive Wandering Mascot Overlay (Active when user idle >= 20s)
            if (!_showGreetingOverlay &&
                !_showThinkingOverlay &&
                _showWanderingOverlay)
              ChatMascotWanderingOverlay(
                targetAvatarGlobalKey: _appBarAvatarKey,
                shouldDismiss: _isDismissingWander,
                onPositionChanged: (pos) {
                  _lastWanderPosition = pos;
                },
                onDismissed: () {
                  if (mounted) {
                    setState(() {
                      _showWanderingOverlay = false;
                      _isDismissingWander = false;
                      _lastWanderPosition = null;
                    });
                    _resetIdleTimer();
                  }
                },
                onUserPromptRequested: () {
                  _focusNode.requestFocus();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      decoration: const BoxDecoration(
        color: AppColors.chatAppBarBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _mascotController,
              builder: (context, _) => _buildAppBarIdentity(),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
            tooltip: 'Menu Opsi',
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder, width: 1),
            ),
            color: AppColors.cardBackground,
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'info') {
                _showExpertiseInfoDialog();
              } else if (value == 'record') {
                _handleQuickRecord();
              } else if (value == 'clear') {
                _confirmClearChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'info',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Dasar Klinis & Kepakaran',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'record',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Catat ke Jurnal Gejala',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'clear',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Bersihkan Percakapan',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
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
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = ClinicalKnowledgeBase.categories[index];
              final isSelected = _controller.selectedCategory == cat;

              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    );
  }

  Widget _buildMessagesList() {
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
            margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.chatNoticeBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.chatNoticeBorder),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
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
          return const ChatMessageEntrance(
            animate: true,
            child: TypingIndicator(),
          );
        }

        final msg = messages[msgIndex];
        final isLatestUser = msg.isUser && msg.id == latestUserId;
        final isNew = _seenMessageIds.add(msg.id);

        return Container(
          key: isLatestUser ? _latestUserMessageKey : ValueKey(msg.id),
          child: ChatMessageEntrance(
            animate: isNew,
            fromRight: msg.isUser,
            child: ChatBubble(
              message: msg,
              isNew: isNew,
              onChipTapped: _handleChipTapped,
              onActionTapped: (route, message) =>
                  _handleAction(route, message: message),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
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
                  border: Border.all(color: AppColors.cardBorder, width: 1),
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
    );
  }

  Widget _buildAppBarIdentity() {
    final statusLabel = _mascotController.statusLabel;

    return InkWell(
      onTap: _toggleMascotInteractive,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _anticipationController,
              builder: (context, child) {
                final val = _anticipationController.value;
                final isWaking = _isWakingUp && val > 0;
                final bounce = isWaking ? math.sin(val * math.pi) * 0.16 : 0.0;
                final tilt = isWaking ? math.sin(val * 4 * math.pi) * 0.08 : 0.0;
                final glowAlpha = isWaking ? (math.sin(val * math.pi) * 0.42).clamp(0.0, 1.0) : 0.0;

                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: glowAlpha > 0.01
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: glowAlpha),
                              blurRadius: 14 * val,
                              spreadRadius: 3 * val,
                            ),
                          ]
                        : null,
                  ),
                  child: Transform.scale(
                    scale: 1.0 + bounce,
                    child: Transform.rotate(
                      angle: tilt,
                      child: Opacity(
                        opacity:
                            (_showGreetingOverlay ||
                                _showThinkingOverlay ||
                                _showWanderingOverlay)
                            ? 0.0
                            : 1.0,
                        child: ChatMascot(
                          key: _appBarAvatarKey,
                          size: 40,
                          mood: isWaking
                              ? ChatMascotMood.question
                              : _mascotController.mood,
                          gazeX: isWaking ? 0.75 : _mascotController.gazeX,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSizes.space8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
                  const SizedBox(height: 1),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      statusLabel,
                      key: ValueKey<String>(statusLabel),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isWakingUp
                            ? AppColors.primary
                            : AppColors.primary,
                        fontWeight: _isWakingUp
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
