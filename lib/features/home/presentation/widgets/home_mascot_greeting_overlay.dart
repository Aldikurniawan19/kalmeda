import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Floating centered greeting popup overlay on HomeScreen.
///
/// Triggered whenever the user opens the app on the Home screen.
/// Plays a welcoming greeting animation with typewriter clinical introduction,
/// then smoothly collapses and flies along a curved Bezier arc down to the bottom
/// floating chatbot mascot button, docking seamlessly into place.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class HomeMascotGreetingOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  final GlobalKey? targetFabGlobalKey;

  const HomeMascotGreetingOverlay({
    super.key,
    required this.onDismissed,
    this.targetFabGlobalKey,
  });

  @override
  State<HomeMascotGreetingOverlay> createState() =>
      _HomeMascotGreetingOverlayState();
}

class _HomeMascotGreetingOverlayState extends State<HomeMascotGreetingOverlay>
    with TickerProviderStateMixin {
  late final String _greetingText;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceProgress;
  late final Animation<double> _bottomDotProgress;
  late final Animation<double> _middleDotProgress;
  late final Animation<double> _topDotProgress;
  late final Animation<double> _cloudBodyProgress;
  late final Animation<double> _textRevealProgress;

  late final AnimationController _flightController;
  late final Animation<double> _flightProgress;

  Timer? _typewriterTimer;
  Timer? _autoDismissTimer;
  int _displayedCharCount = 0;
  bool _isTypingMessage = false;
  bool _isFlying = false;

  @override
  void initState() {
    super.initState();

    // Personalize greeting with logged in user's first name
    final user = AuthController().currentUser;
    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim().split(' ').first
        : '';
    _greetingText = userName.isNotEmpty
        ? 'Halo, $userName! Bagaimana kabarmu hari ini? Aku Konsultan Medis Kalmeda, siap membantumu. Ada keluhan atau pertanyaan siklus yang ingin dikonsultasikan?'
        : 'Halo! Bagaimana kabarmu hari ini? Aku Konsultan Medis Kalmeda, siap membantumu. Ada keluhan atau pertanyaan siklus yang ingin dikonsultasikan?';

    // 1. Entrance Controller (Mascot popup followed by staged cloud thought emergence: ~1400ms)
    // Sequence: Mascot pop -> Bottom dot -> Middle dot -> Top dot -> Cloud body expands -> Text reveal
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _entranceProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _bottomDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.32, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    _middleDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.44, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _topDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.54, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _cloudBodyProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _textRevealProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.86, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Direct Diagonal Flight Controller (Straight glide from center popup directly to bottom-right FAB)
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _flightProgress = CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    );

    _flightController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          widget.onDismissed();
        }
      }
    });

    _entranceController.forward().then((_) {
      if (mounted && !_isFlying) {
        _startTypewriterEffect();
      }
    });
    MascotSoundService().playSound(MascotSoundType.pop);
  }

  void _startTypewriterEffect() {
    setState(() {
      _isTypingMessage = true;
    });

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 32), (
      timer,
    ) {
      if (!mounted || _isFlying) {
        timer.cancel();
        return;
      }
      if (_displayedCharCount < _greetingText.length) {
        setState(() {
          _displayedCharCount++;
        });
      } else {
        setState(() {
          _isTypingMessage = false;
        });
        timer.cancel();

        // After typing completes, pause 2.2s for reading then start direct diagonal flight
        _autoDismissTimer = Timer(const Duration(milliseconds: 2200), () {
          if (mounted && !_isFlying) {
            _triggerExitFlight();
          }
        });
      }
    });
  }

  void _triggerExitFlight() {
    if (_isFlying) return;
    _isFlying = true;
    _typewriterTimer?.cancel();
    _autoDismissTimer?.cancel();

    setState(() {
      _displayedCharCount = _greetingText.length;
      _isTypingMessage = false;
    });

    MascotSoundService().playSound(MascotSoundType.swoop);
    _flightController.forward();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _autoDismissTimer?.cancel();
    _entranceController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  /// Calculates the exact pixel vector from the screen center to the bottom floating mascot FAB
  Offset _calculateTargetOffset(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (widget.targetFabGlobalKey != null) {
      final fabBox =
          widget.targetFabGlobalKey!.currentContext?.findRenderObject()
              as RenderBox?;
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (fabBox != null &&
          fabBox.hasSize &&
          overlayBox != null &&
          overlayBox.hasSize) {
        // Target the center of the 62x62 mascot inside the FAB
        final mascotLocalCenter = Offset(
          fabBox.size.height / 2,
          fabBox.size.height / 2,
        );
        final fabCenterGlobal = fabBox.localToGlobal(mascotLocalCenter);
        final overlayTopLeftGlobal = overlayBox.localToGlobal(Offset.zero);
        final fabInOverlay = fabCenterGlobal - overlayTopLeftGlobal;
        final overlayCenter = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        return fabInOverlay - overlayCenter;
      }
    }

    // Deterministic fallback to standard FAB bottom-right position (margin 16 right, above 64px bottom nav)
    const mascotSize = 62.0;
    final fallbackFabCenterX = constraints.maxWidth - 16.0 - (mascotSize / 2);
    final fallbackFabCenterY = constraints.maxHeight - 88.0 - (mascotSize / 2);
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    return Offset(
      fallbackFabCenterX - centerX,
      fallbackFabCenterY - centerY,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _greetingText.substring(0, _displayedCharCount);

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_entranceController, _flightController]),
            builder: (context, _) {
              final entrance = _entranceProgress.value;
              final flightVal = _flightProgress.value;

              final targetOffset = _calculateTargetOffset(context, constraints);
              const startCenterOffset = Offset(0, 32);

              const startSize = 138.0;
              const targetSize = 62.0;
              const fabScale = targetSize / startSize; // ~0.449

              // Exact diagonal vector from popup position to bottom-right FAB coordinate
              final deltaX = targetOffset.dx - startCenterOffset.dx;
              final deltaY = targetOffset.dy - startCenterOffset.dy;
              final flightAngle = math.atan2(deltaY, deltaX);

              Offset currentOffset;
              double baseScale;
              double bankTilt;
              double flightStretch;

              if (flightVal == 0.0) {
                // Phase 1: Popping into center from lower center
                final entranceLift = math.sin(entrance * math.pi) * 14.0;
                currentOffset = Offset(
                  startCenterOffset.dx,
                  startCenterOffset.dy + (1 - entrance) * 60.0 - entranceLift,
                );
                baseScale = entrance;
                bankTilt = 0.06 * math.sin(entrance * math.pi);
                flightStretch = 0.04 * math.sin(entrance * math.pi);
              } else {
                // Phase 2: 100% direct diagonal straight line straight to the bottom-right FAB
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
                  )!,
                );
                baseScale = ui.lerpDouble(1.0, fabScale, flightVal)!;
                // Aerodynamic directional tilt: mereng ke arah kanan-bawah selama meluncur
                bankTilt = flightAngle * 0.45 * math.sin(flightVal * math.pi);
                flightStretch = 0.12 * math.sin(flightVal * math.pi);
              }

              // Idle floating hover bob (only while in center popup)
              final t = _entranceController.value * 2 * math.pi * 4;
              final entranceHoverWeight = ((entrance - 0.85) / 0.15).clamp(
                0.0,
                1.0,
              );
              final hoverY = (flightVal == 0.0)
                  ? (math.sin(t) * 4.5 * entranceHoverWeight)
                  : 0.0;

              final mascotTranslateX = currentOffset.dx;
              final mascotTranslateY = currentOffset.dy + hoverY;

              final mascotScaleX = baseScale * (1.0 - flightStretch * 0.5);
              final mascotScaleY = baseScale * (1.0 + flightStretch * 0.8);

              // Staged thought bubble progress during entrance, and clean collapse during flight
              final flightDismiss = (1.0 - flightVal * 2.2).clamp(0.0, 1.0);
              final cloudScale = (_cloudBodyProgress.value * flightDismiss).clamp(0.0, 1.2);
              final topDotScale = (_topDotProgress.value * flightDismiss).clamp(0.0, 1.2);
              final midDotScale = (_middleDotProgress.value * flightDismiss).clamp(0.0, 1.2);
              final botDotScale = (_bottomDotProgress.value * flightDismiss).clamp(0.0, 1.2);

              final textOpacity = (_textRevealProgress.value * (1.0 - flightVal * 3.0)).clamp(0.0, 1.0);
              final bubbleVisible = (botDotScale > 0.01 || cloudScale > 0.01) && flightVal < 0.45;

              final backdropOpacity = ((1.0 - flightVal) * entrance).clamp(
                0.0,
                1.0,
              );

              // Ultra-smooth progressive color morphing from white 3D Coucou into Home pastel rose
              final currentTopColor = Color.lerp(
                Colors.white,
                const Color(0xFFFFF0F3),
                flightVal,
              );
              final currentBottomColor = Color.lerp(
                const Color(0xFF888896),
                const Color(0xFFFFCCD5),
                flightVal,
              );
              final currentGlowColor = Color.lerp(
                Colors.white.withValues(alpha: 0.18),
                AppColors.primary,
                flightVal,
              );

              final currentMood = flightVal > 0.04
                  ? ChatMascotMood.idle
                  : ChatMascotMood.greeting;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Non-skippable modal barrier: Absorb all taps so user cannot
                  // accidentally or intentionally dismiss, cancel, or fast-forward the animation.
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Frosted Glass Backdrop
                    if (backdropOpacity > 0.01)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: backdropOpacity,
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 5 * backdropOpacity,
                                sigmaY: 5 * backdropOpacity,
                              ),
                              child: Container(
                                color: Colors.black.withValues(
                                  alpha: 0.28 * backdropOpacity,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 2. Centered Floating Asymmetrical Thought Bubble (emerges progressively from bottom dots up to cloud)
                    if (bubbleVisible)
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, hoverY - 78),
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

                    // 3. Greeting Mascot Component
                    Transform.translate(
                      offset: Offset(mascotTranslateX, mascotTranslateY),
                      child: Transform.rotate(
                        angle: bankTilt,
                        child: Transform.scale(
                          scaleX: mascotScaleX,
                          scaleY: mascotScaleY,
                          child: SizedBox(
                            width: startSize,
                            height: startSize,
                            child: ChatMascot(
                              size: startSize,
                              mood: currentMood,
                              customTopColor: currentTopColor,
                              customBottomColor: currentBottomColor,
                              customGlowColor: currentGlowColor,
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
