import 'dart:async';

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Floating living mascot button on HomeScreen replacing the old chatbot FAB.
///
/// Features:
/// 1. Living procedural Mochi mascot component with sweet pastel rose Home theme.
/// 2. Clean floating character with no circular container background behind it.
/// 3. Expandable pill with "Tanya Kalmeda" label without any overflow.
/// 4. Periodic 5-second interactive question thought bubble popping up above the mascot.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class HomeMascotFab extends StatefulWidget {
  final bool isExtended;
  final bool isVisible;
  final VoidCallback onTap;
  final GlobalKey? fabKey;

  const HomeMascotFab({
    super.key,
    required this.isExtended,
    required this.onTap,
    this.isVisible = true,
    this.fabKey,
  });

  @override
  State<HomeMascotFab> createState() => _HomeMascotFabState();
}

class _HomeMascotFabState extends State<HomeMascotFab>
    with SingleTickerProviderStateMixin {
  static const List<String> _questionPrompts = [
    'Bagaimana kabarmu hari ini?',
    'Ada keluhan hari ini?',
    'Mau catat siklus haid?',
    'Siklusmu teratur?',
    'Perlu tips fase Luteal?',
    'Konsultasi sekarang?',
    'Mau cek masa subur?',
    'Ada gejala fisik PMS?',
  ];

  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleScale;
  late final Animation<double> _bubbleOpacity;

  Timer? _periodicBubbleTimer;
  Timer? _dismissBubbleTimer;
  int _promptIndex = 0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _bubbleScale = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _bubbleOpacity = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    if (widget.isVisible) {
      _startPeriodicBubbleCycle();
    }
  }

  @override
  void didUpdateWidget(covariant HomeMascotFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      _startPeriodicBubbleCycle();
    } else if (oldWidget.isVisible && !widget.isVisible) {
      _stopPeriodicBubbleCycle();
    }
  }

  void _startPeriodicBubbleCycle() {
    _stopPeriodicBubbleCycle();

    _periodicBubbleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !widget.isVisible || widget.isExtended) return;
      _showNextQuestionBubble();
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && widget.isVisible && !widget.isExtended) {
        _showNextQuestionBubble();
      }
    });
  }

  void _showNextQuestionBubble() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _questionPrompts.length;
    });
    _bubbleController.forward(from: 0.0);

    _dismissBubbleTimer?.cancel();
    _dismissBubbleTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _bubbleController.reverse();
      }
    });
  }

  void _stopPeriodicBubbleCycle() {
    _periodicBubbleTimer?.cancel();
    _dismissBubbleTimer?.cancel();
    _bubbleController.reverse();
  }

  @override
  void dispose() {
    _periodicBubbleTimer?.cancel();
    _dismissBubbleTimer?.cancel();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const mascotSize = 62.0;
    final isExtended = widget.isExtended;

    return Opacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // 1. Floating Question Thought Bubble (Appears every 5 seconds)
          if (!isExtended)
            Positioned(
              bottom: mascotSize + 8,
              right: 0,
              child: AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) {
                  if (_bubbleController.value <= 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Transform.scale(
                    scale: _bubbleScale.value,
                    alignment: const Alignment(0.75, 1.0),
                    child: Opacity(
                      opacity: _bubbleOpacity.value,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onTap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Main Thought Capsule
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                  const BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 11.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    _questionPrompts[_promptIndex],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Thought Bubble Connecting Tail Dots leading down to mascot
                            Padding(
                              padding: const EdgeInsets.only(right: 22, top: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildThoughtDot(7.0),
                                  const SizedBox(height: 2),
                                  _buildThoughtDot(4.5),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 2. Main Mascot Floating Action Component (With Sweet Pastel Rose Home Colors)
          GestureDetector(
            key: widget.fabKey,
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              MascotSoundService().playSound(MascotSoundType.pop);
              widget.onTap();
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                height: mascotSize,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        color: isExtended
                            ? AppColors.cardBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(mascotSize / 2),
                        border: isExtended
                            ? Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.4,
                              )
                            : null,
                        boxShadow: isExtended
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                                const BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: isExtended ? Clip.antiAlias : Clip.none,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Living Mochi Mascot with sweet pastel rose Home colors
                          const SizedBox(
                            width: mascotSize,
                            height: mascotSize,
                            child: ChatMascot(
                              size: mascotSize,
                              mood: ChatMascotMood.idle,
                              customTopColor: Color(0xFFFFF0F3),
                              customBottomColor: Color(0xFFFFCCD5),
                              customGlowColor: AppColors.primary,
                            ),
                          ),

                          // Collapsing label when extended
                          ClipRect(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                              width: isExtended ? 122.0 : 0.0,
                              alignment: Alignment.centerLeft,
                              child: AnimatedOpacity(
                                duration: Duration(
                                  milliseconds: isExtended ? 320 : 100,
                                ),
                                curve: Curves.easeInOut,
                                opacity: isExtended ? 1.0 : 0.0,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 14),
                                  child: Text(
                                    'Tanya Kalmeda',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
