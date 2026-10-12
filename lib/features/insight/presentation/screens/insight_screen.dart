import 'dart:async';

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/features/insight/presentation/widgets/activity_notes_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/cycle_history_chart_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_banner_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_header.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_metrics_bar.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_tip_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/mood_condition_chart_card.dart';

/// Insight Screen displaying health trends, cycle statistics, and mood analytics.
class InsightScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTapped;
  final bool showBottomNav;

  const InsightScreen({
    super.key,
    this.onNavTapped,
    this.showBottomNav = false,
  });

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  int _currentNavIndex = 3;

  @override
  void initState() {
    super.initState();
    HomeController().loadData(silent: true);
  }

  void _handleNavTapped(int index) {
    if (widget.onNavTapped != null) {
      widget.onNavTapped!(index);
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space20,
            vertical: AppSizes.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InsightHeader(onBack: () => _handleNavTapped(0)),
              const SizedBox(height: AppSizes.space14),

              // Summary banner
              const InsightBannerCard(),
              const SizedBox(height: AppSizes.space20),

              // Interactive Clinical Chatbot Consultation Card with Living Mascot & Typewriter
              _ChatbotConsultationCard(
                onTap: (pos) => ChatbotScreen.open(
                  context,
                  onNavigateTab: widget.onNavTapped,
                  initialFabPosition: pos,
                ),
              ),
              const SizedBox(height: AppSizes.space20),

              // Dynamic cycle summary metrics bar
              const InsightMetricsBar(),
              const SizedBox(height: AppSizes.space20),

              // Cycle history bar chart
              const CycleHistoryChartCard(),
              const SizedBox(height: AppSizes.space20),

              // Mood & condition distribution donut chart
              const MoodConditionChartCard(),
              const SizedBox(height: AppSizes.space20),

              // Activity & Notes overview
              const ActivityNotesCard(),
              const SizedBox(height: AppSizes.space16),

              // Health tip card
              const InsightTipCard(),
              const SizedBox(height: AppSizes.space32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? HomeBottomNavbar(
              selectedIndex: _currentNavIndex,
              onItemTapped: _handleNavTapped,
            )
          : null,
    );
  }
}

class _ChatbotConsultationCard extends StatefulWidget {
  final void Function(Offset? mascotGlobalPos) onTap;

  const _ChatbotConsultationCard({required this.onTap});

  @override
  State<_ChatbotConsultationCard> createState() =>
      _ChatbotConsultationCardState();
}

class _ChatbotConsultationCardState extends State<_ChatbotConsultationCard> {
  static const List<String> _typewriterPhrases = [
    'Punya keluhan nyeri, siklus telat, atau mitos?',
    'Mau cek pola gejala PMS atau masa suburmu?',
    'Konsultasikan pertanyaan dengan dokter Sp.OG & ACOG.',
    'Dapatkan rekomendasi nutrisi untuk fase siklusmu.',
  ];

  final GlobalKey _mascotKey = GlobalKey();
  Timer? _typingTimer;
  Timer? _cursorTimer;
  Timer? _holdTimer;

  int _phraseIndex = 0;
  int _charIndex = 0;
  bool _isTyping = true;
  bool _isDeleting = false;
  bool _showCursor = true;
  bool _isPressed = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _startTypewriter();
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _startTypewriter() {
    _typingTimer?.cancel();
    _holdTimer?.cancel();
    _isTyping = true;
    _isDeleting = false;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final currentPhrase = _typewriterPhrases[_phraseIndex];
      if (_charIndex < currentPhrase.length) {
        setState(() {
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
        _holdTimer = Timer(const Duration(milliseconds: 3500), () {
          if (!mounted) return;
          _startDeleting();
        });
      }
    });
  }

  void _startDeleting() {
    _typingTimer?.cancel();
    _holdTimer?.cancel();
    _isTyping = true;
    _isDeleting = true;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex > 0) {
        setState(() {
          _charIndex--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _isDeleting = false;
          _phraseIndex = (_phraseIndex + 1) % _typewriterPhrases.length;
        });
        _holdTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted) {
            _startTypewriter();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _handleCardTap() {
    Offset? pos;
    final renderBox =
        _mascotKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      pos = renderBox.localToGlobal(const Offset(26, 26));
    }
    widget.onTap(pos);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhrase = _typewriterPhrases[_phraseIndex];
    final currentText = currentPhrase.substring(
      0,
      _charIndex.clamp(0, currentPhrase.length),
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: const Color(0xFFFFCCDA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D79).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Title and Typewriter Speech Bubble emerging towards Mascot
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tanya Asisten Medis Kalmeda',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sp.OG',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Speech-like Typewriter Description Bubble with Fixed Dimension
                    Container(
                      width: double.infinity,
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          width: 1.0,
                        ),
                      ),
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: currentText,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: _showCursor ? '|' : ' ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 2. Living Procedural Mochi Mascot positioned on the RIGHT side of the card
              GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: _handleCardTap,
                child: SizedBox(
                  key: _mascotKey,
                  width: 52,
                  height: 52,
                  child: ChatMascot(
                    size: 52,
                    mood: _isPressed
                        ? ChatMascotMood.greeting
                        : ChatMascotMood.idle,
                    isTalking: _isTyping && !_isDeleting,
                    customTopColor: const Color(0xFFFFF0F3),
                    customBottomColor: const Color(0xFFFFCCD5),
                    customGlowColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),
          const Text(
            'Konsultasikan pertanyaan seputar kesehatan reproduksi secara interaktif dengan panduan klinis terverifikasi (ACOG & Kemenkes RI).',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space12),
          GestureDetector(
            onTapDown: (_) => setState(() => _isButtonPressed = true),
            onTapUp: (_) => setState(() => _isButtonPressed = false),
            onTapCancel: () => setState(() => _isButtonPressed = false),
            child: AnimatedScale(
              scale: _isButtonPressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleCardTap,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Ada Pertanyaan? Chat Yuk!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
