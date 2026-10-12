import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Floating centered greeting popup overlay inspired by Mochi in Coucou (https://github.com/Louis-CFM/coucou.git).
///
/// Features:
/// 1. Smooth physical entrance: Swoops out from the top-left AppBar avatar slot down to the center.
/// 2. Centered floating mascot with speech mouth articulation and typewriter intro text.
/// 3. Unique asymmetrical organic thought cloud bubble with right-side connecting tail dots.
/// 4. Frosted glass full-screen blurred background (`BackdropFilter`).
/// 5. Coucou-style Return-to-Home Flight:
///    - Thought bubble collapses cleanly into the character first (anticipation).
///    - Mascot takes off with a dynamic curved arc (parabolic Bezier swoop).
///    - Dynamic banking tilt (-16°) and velocity squash-and-stretch during flight.
///    - Smooth scaling from 118pt down to 40pt to dock seamlessly into the top-left AppBar avatar slot.
///    - Landing settle bounce into the target position with zero visual discontinuity.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatMascotGreetingOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  final GlobalKey? targetAvatarGlobalKey;
  final Offset? initialFabPosition;

  const ChatMascotGreetingOverlay({
    super.key,
    required this.onDismissed,
    this.targetAvatarGlobalKey,
    this.initialFabPosition,
  });

  @override
  State<ChatMascotGreetingOverlay> createState() =>
      _ChatMascotGreetingOverlayState();
}

class _ChatMascotGreetingOverlayState extends State<ChatMascotGreetingOverlay>
    with SingleTickerProviderStateMixin {
  late final String _fullMessage;

  late final AnimationController _controller;
  late final Animation<double> _entranceProgress;
  late final Animation<double> _fadeIn;
  late final Animation<double> _bottomDotProgress;
  late final Animation<double> _middleDotProgress;
  late final Animation<double> _topDotProgress;
  late final Animation<double> _cloudBodyProgress;
  late final Animation<double> _textRevealProgress;
  late final Animation<double> _bubbleDismissProgress;
  late final Animation<double> _flightProgress;
  late final Animation<double> _landingProgress;

  Timer? _typewriterTimer;
  int _displayedCharCount = 0;
  bool _isTypingMessage = false;

  @override
  void initState() {
    super.initState();

    // Personalize greeting with logged in user's first name
    final user = AuthController().currentUser;
    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim().split(' ').first
        : '';
    _fullMessage = userName.isNotEmpty
        ? 'Halo, $userName! Bagaimana kabarmu hari ini? Aku Konsultan Medis Kalmeda. Ceritakan apa yang sedang kamu rasakan atau tanyakan seputar siklus haidmu, ya...'
        : 'Halo! Bagaimana kabarmu hari ini? Aku Konsultan Medis Kalmeda. Ceritakan apa yang sedang kamu rasakan atau tanyakan seputar siklus haidmu, ya...';

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    );

    // 1. Entrance swoop from Home FAB / AppBar avatar to center (0.00 -> 0.16, ~1200ms)
    _entranceProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.16, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.04, curve: Curves.easeOut),
      ),
    );

    // 2. Staged Thought Cloud Emergence (0.16 -> 0.36) - emerges from bottom dots up to full cloud
    _bottomDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    _middleDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.19, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _topDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.28, curve: Curves.easeOutCubic),
      ),
    );

    _cloudBodyProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.33, curve: Curves.easeOutCubic),
      ),
    );

    _textRevealProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.37, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Thought Bubble Collapse & Anticipation: 0.78 -> 0.84 (~450ms)
    _bubbleDismissProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 0.84, curve: Curves.easeInBack),
      ),
    );

    // 4. Coucou Bezier Flight Arc to AppBar: 0.84 -> 0.96 (~900ms)
    _flightProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84, 0.96, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Landing Settle & Docking into AppBar avatar: 0.96 -> 1.00 (~300ms)
    _landingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.96, 1.00, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });

    MascotSoundService().playSound(MascotSoundType.pop);
    _startTypewriterEffect();
  }

  void _startTypewriterEffect() {
    // Wait until mascot has swooped into center and thought cloud has fully emerged (~2500ms)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _isTypingMessage = true;
      });
      // Relaxed typewriter pacing (~40ms per character)
      _typewriterTimer = Timer.periodic(const Duration(milliseconds: 40), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_displayedCharCount < _fullMessage.length) {
          setState(() {
            _displayedCharCount++;
          });
        } else {
          setState(() {
            _isTypingMessage = false;
          });
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Calculates the exact pixel vector from the screen center to the top-left AppBar mascot avatar
  Offset _calculateTargetOffset(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (widget.targetAvatarGlobalKey != null) {
      final avatarBox =
          widget.targetAvatarGlobalKey!.currentContext?.findRenderObject()
              as RenderBox?;
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (avatarBox != null &&
          avatarBox.hasSize &&
          overlayBox != null &&
          overlayBox.hasSize) {
        final avatarCenterGlobal = avatarBox.localToGlobal(
          Offset(avatarBox.size.width / 2, avatarBox.size.height / 2),
        );
        final overlayTopLeftGlobal = overlayBox.localToGlobal(Offset.zero);
        final avatarInOverlay = avatarCenterGlobal - overlayTopLeftGlobal;
        final overlayCenter = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        return avatarInOverlay - overlayCenter;
      }
    }

    // Deterministic fallback based on standard AppBar layout (IconButton 48 + mascot 40/2 = 68, kToolbarHeight/2 = 28)
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    return Offset(68.0 - centerX, 28.0 - centerY);
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _fullMessage.substring(0, _displayedCharCount);

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final entrance = _entranceProgress.value;
              final flightVal = _flightProgress.value;
              final bubbleDismissVal = _bubbleDismissProgress.value;
              final landingVal = _landingProgress.value;

              final targetOffset = _calculateTargetOffset(context, constraints);
              const startCenterOffset = Offset(0, 68);

              const startSize = 130.0;
              const targetSize = 40.0;
              const avatarScale = targetSize / startSize; // ~0.308

              final overlayBox = context.findRenderObject() as RenderBox?;
              final overlayTopLeftGlobal =
                  overlayBox != null && overlayBox.hasSize
                  ? overlayBox.localToGlobal(Offset.zero)
                  : Offset.zero;

              final overlayCenter = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight / 2,
              );

              final startFabInOverlay = widget.initialFabPosition != null
                  ? (widget.initialFabPosition! - overlayTopLeftGlobal)
                  : null;

              final startEntranceOffset = startFabInOverlay != null
                  ? (startFabInOverlay - overlayCenter)
                  : targetOffset;

              final startEntranceScale = widget.initialFabPosition != null
                  ? (54.0 / startSize)
                  : avatarScale;

              Offset currentOffset;
              double baseScale;
              double bankTilt;
              double flightStretch;

              if (flightVal == 0.0) {
                // Phase 1: Swooping in from Home FAB / Insight Card / AppBar avatar to center
                final deltaX = startCenterOffset.dx - startEntranceOffset.dx;
                final deltaY = startCenterOffset.dy - startEntranceOffset.dy;
                final dist = math.sqrt(deltaX * deltaX + deltaY * deltaY);
                final normalX = dist > 0 ? -deltaY / dist : 0.0;
                final normalY = dist > 0 ? deltaX / dist : 0.0;

                final curveDirection = (startEntranceOffset.dx < 0)
                    ? -1.0
                    : 1.0;
                final arcAmount =
                    math.sin(entrance * math.pi) * (dist > 160 ? 46.0 : 28.0);

                currentOffset = Offset(
                  ui.lerpDouble(
                        startEntranceOffset.dx,
                        startCenterOffset.dx,
                        entrance,
                      )! +
                      normalX * arcAmount * curveDirection,
                  ui.lerpDouble(
                        startEntranceOffset.dy,
                        startCenterOffset.dy,
                        entrance,
                      )! +
                      normalY * arcAmount * curveDirection,
                );
                baseScale = ui.lerpDouble(startEntranceScale, 1.0, entrance)!;
                final isFromRight = startEntranceOffset.dx > 0;
                bankTilt =
                    (isFromRight ? -0.24 : 0.24) * math.sin(entrance * math.pi);
                flightStretch = math.sin(entrance * math.pi) * 0.14;
              } else {
                // Phase 2: Swooping back from center to AppBar avatar
                final arcLift = math.sin(flightVal * math.pi) * 38.0;
                currentOffset = Offset(
                  ui.lerpDouble(
                    startCenterOffset.dx,
                    targetOffset.dx,
                    flightVal,
                  )!,
                  ui.lerpDouble(
                        startCenterOffset.dy,
                        targetOffset.dy,
                        flightVal,
                      )! -
                      arcLift,
                );
                baseScale = ui.lerpDouble(1.0, avatarScale, flightVal)!;
                bankTilt = -math.sin(flightVal * math.pi) * 0.26;
                flightStretch = math.sin(flightVal * math.pi) * 0.12;
              }

              // Idle floating hover bob with smooth continuous envelope
              final t = _controller.value * 2 * math.pi * 5;
              final entranceHoverWeight = ((entrance - 0.85) / 0.15).clamp(
                0.0,
                1.0,
              );
              final exitHoverWeight = (1.0 - bubbleDismissVal).clamp(0.0, 1.0);
              final hoverWeight = entranceHoverWeight * exitHoverWeight;
              final hoverY = (flightVal == 0.0)
                  ? (math.sin(t) * 4.5 * hoverWeight)
                  : 0.0;

              // Combined translation vector
              final mascotTranslateX = currentOffset.dx;
              final mascotTranslateY = currentOffset.dy + hoverY;

              // Entrance landing squishy settle bounce (at entrance > 0.82)
              final entranceLandingSquash =
                  (flightVal == 0.0 && entrance > 0.82)
                  ? (math.sin((entrance - 0.82) / 0.18 * math.pi) * 0.12)
                  : 0.0;

              // Landing settle squash
              final landingSquash = (landingVal > 0)
                  ? (math.sin(landingVal * math.pi) * 0.08)
                  : entranceLandingSquash;

              // Anticipation crouch before return flight
              final anticipationSquashX =
                  (flightVal == 0 && bubbleDismissVal > 0)
                  ? (1.0 + bubbleDismissVal * 0.07)
                  : 1.0;
              final anticipationSquashY =
                  (flightVal == 0 && bubbleDismissVal > 0)
                  ? (1.0 - bubbleDismissVal * 0.07)
                  : 1.0;

              final scaleX =
                  baseScale *
                  anticipationSquashX *
                  (1.0 - flightStretch * 0.5 + landingSquash * 0.8);
              final scaleY =
                  baseScale *
                  anticipationSquashY *
                  (1.0 + flightStretch - landingSquash * 0.9);

              // Frosted Glass Blur & Background Dim Dissolve
              final activeAlpha = (entrance * (1.0 - flightVal)).clamp(
                0.0,
                1.0,
              );
              final currentBlur = (6.0 * _fadeIn.value * activeAlpha).clamp(
                0.0,
                6.0,
              );
              final currentDim = (0.26 * _fadeIn.value * activeAlpha).clamp(
                0.0,
                0.26,
              );

              // Staged Thought Bubble Scales during entrance & flight collapse
              final dismissFactor = (1.0 - bubbleDismissVal).clamp(0.0, 1.0);
              final cloudScale = (_cloudBodyProgress.value * dismissFactor).clamp(0.0, 1.2);
              final topDotScale = (_topDotProgress.value * dismissFactor).clamp(0.0, 1.2);
              final midDotScale = (_middleDotProgress.value * dismissFactor).clamp(0.0, 1.2);
              final botDotScale = (_bottomDotProgress.value * dismissFactor).clamp(0.0, 1.2);

              final textOpacity = (_textRevealProgress.value * (1.0 - bubbleDismissVal * 2.0)).clamp(0.0, 1.0);
              final bubbleVisible = (botDotScale > 0.01 || cloudScale > 0.01) && bubbleDismissVal < 0.95;

              // Mascot Gaze & Mood
              final isFlying = entrance < 0.95 || flightVal > 0.02;
              final isGreetingIntro = _controller.value < 0.78;
              final mascotMood = isFlying
                  ? ChatMascotMood.idle
                  : (isGreetingIntro
                        ? ChatMascotMood.greeting
                        : ChatMascotMood.happy);
              final mascotGazeX = isFlying
                  ? (flightVal > 0 ? -0.6 : 0.4)
                  : (bubbleDismissVal > 0 ? -0.85 : 0.0);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Non-skippable modal barrier: Absorb all taps so the user cannot
                  // accidentally or intentionally dismiss, cancel, or fast-forward the animation.
                },
                child: Stack(
                  children: [
                    // 1. Frosted Glass Blurred Backdrop covering entire screen
                    if (currentBlur > 0.1)
                      Positioned.fill(
                        child: Opacity(
                          opacity: activeAlpha,
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: currentBlur,
                              sigmaY: currentBlur,
                            ),
                            child: Container(
                              color: Colors.white.withValues(alpha: currentDim * 0.75),
                            ),
                          ),
                        ),
                      ),

                    // 2. Centered Floating Thought Bubble (emerges progressively from bottom dots up to cloud)
                    if (bubbleVisible)
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, hoverY - 64),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 330,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Asymmetrical thought cloud (scales outward from tail connection point)
                                  _buildAsymmetricalCloudBubble(
                                    currentText,
                                    cloudScale,
                                    textOpacity,
                                  ),
                                  // Connecting thought dots emerging progressively from bottom up to cloud
                                  _buildThoughtTail(
                                    topDotScale,
                                    midDotScale,
                                    botDotScale,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 3. Coucou Flying Mascot (swoops in from Home FAB / AppBar, greets in center, swoops to AppBar)
                    Center(
                      child: Transform.translate(
                        offset: Offset(mascotTranslateX, mascotTranslateY),
                        child: Transform.rotate(
                          angle: bankTilt,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              scaleX,
                              scaleY,
                              1.0,
                            ),
                            child: SizedBox.square(
                              dimension: startSize,
                              child: Center(
                                child: ChatMascot(
                                  size: startSize,
                                  mood: mascotMood,
                                  isTalking: !isFlying && _isTypingMessage,
                                  gazeX: mascotGazeX,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Renders the unique asymmetrical organic thought cloud bubble with tail pocket on the right
  Widget _buildAsymmetricalCloudBubble(
    String currentText,
    double cloudScale,
    double textOpacity,
  ) {
    if (cloudScale <= 0.01) return const SizedBox.shrink();

    final textSlideY = (1.0 - textOpacity) * 6.0;

    return Transform.scale(
      scale: cloudScale,
      alignment: const Alignment(0.48, 1.0),
      child: Opacity(
        opacity: cloudScale.clamp(0.0, 1.0),
        child: CustomPaint(
          painter: _AsymmetricThoughtCloudPainter(
            fillColor: AppColors.cardBackground,
            borderColor: AppColors.primarySoft,
            borderWidth: 1.6,
            shadowColor: AppColors.primary.withValues(alpha: 0.20),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(26, 26, 28, 24),
            child: Center(
              child: Opacity(
                opacity: textOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, textSlideY),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: currentText,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.52,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (_isTypingMessage && textOpacity > 0.8)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: 2.2,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(1),
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
      ),
    );
  }

  /// Descending thought bubble dots emerging progressively from bottom up to cloud
  Widget _buildThoughtTail(
    double topScale,
    double midScale,
    double botScale,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 52, top: 4, bottom: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Top dot (largest, closest to right-side pocket of cloud)
            Transform.scale(
              scale: topScale,
              child: Opacity(
                opacity: topScale.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 18),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2.5),
            // Middle dot (diagonal step toward mascot's right side)
            Transform.scale(
              scale: midScale,
              child: Opacity(
                opacity: midScale.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 28),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2.5),
            // Bottom dot (smallest, emerging directly above mascot's right head/shoulder)
            Transform.scale(
              scale: botScale,
              child: Opacity(
                opacity: botScale.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 38),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering a unique, ASYMMETRICAL thought cloud with tail contour on the RIGHT side.
class _AsymmetricThoughtCloudPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;

  const _AsymmetricThoughtCloudPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
  });

  Path _buildAsymmetricCloudPath(Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 1.0 || h <= 1.0) return Path();
    final path = Path();

    // Asymmetric Cloud Path with tail connection pocket on the RIGHT side:
    path.moveTo(w * 0.10, h * 0.22);

    // 1. Top Edge: Left-top buoyant puff, dynamic mid puff, and sloped right puff
    path.arcToPoint(
      Offset(w * 0.46, h * 0.05),
      radius: Radius.circular(w * 0.24),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.82, h * 0.12),
      radius: Radius.circular(w * 0.26),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.98, h * 0.32),
      radius: Radius.circular(w * 0.17),
      clockwise: true,
    );

    // 2. Right Edge: Curving down towards the right thought pocket
    path.arcToPoint(
      Offset(w * 0.95, h * 0.68),
      radius: Radius.circular(h * 0.30),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.88, h * 0.85),
      radius: Radius.circular(h * 0.20),
      clockwise: true,
    );

    // 3. Bottom Edge: Distinct thought tail contour on the RIGHT side, curving to bottom-left
    path.arcToPoint(
      Offset(w * 0.72, h * 0.97),
      radius: Radius.circular(w * 0.18),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.40, h * 0.94),
      radius: Radius.circular(w * 0.22),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.14, h * 0.82),
      radius: Radius.circular(w * 0.18),
      clockwise: true,
    );

    // 4. Left Edge: Organic tall curved flank returning to top-left
    path.arcToPoint(
      Offset(w * 0.02, h * 0.48),
      radius: Radius.circular(h * 0.28),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(w * 0.10, h * 0.22),
      radius: Radius.circular(h * 0.20),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildAsymmetricCloudPath(size);

    // Soft organic glow shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Crisp subtle drop shadow
    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0x0E000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Stroke Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _AsymmetricThoughtCloudPainter oldDelegate) =>
      false;
}
