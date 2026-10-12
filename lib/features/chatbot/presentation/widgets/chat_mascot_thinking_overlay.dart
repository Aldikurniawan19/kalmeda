import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Floating popup overlay showing the mascot component during AI thinking / processing.
///
/// Features:
/// 1. Smooth entrance: Swoops out gracefully from top-left AppBar avatar or wander position to the center.
/// 2. Multi-Stage Voice Processing:
///    - Stage 1 (0-1.4s): Active listening mode (`ChatMascotMood.listening`) with concentric acoustic pulse rings
///      and animated equalizer badge *"Mendengarkan rekaman suara..."*.
///    - Stage 2 (1.4s+): Pensive synthesizing mode (`ChatMascotMood.thinking`) with glowing thought aura
///      and badge *"Menganalisis keluhan klinis..."*.
/// 3. Text Processing Mode: Pensive floating bob in `ChatMascotMood.thinking` with clinical badge.
/// 4. Answer Found Celebration: Double hop, blooming diamond stars, and joyful smile in `ChatMascotMood.happy`.
/// 5. Coucou return-to-home flight: Parabolic Bezier return flight docking into the AppBar avatar slot.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatMascotThinkingOverlay extends StatefulWidget {
  final bool isGenerating;
  final bool isVoiceNote;
  final VoidCallback onDismissed;
  final GlobalKey? targetAvatarGlobalKey;
  final Offset? initialPositionInOverlay;

  const ChatMascotThinkingOverlay({
    super.key,
    required this.isGenerating,
    this.isVoiceNote = false,
    required this.onDismissed,
    this.targetAvatarGlobalKey,
    this.initialPositionInOverlay,
  });

  @override
  State<ChatMascotThinkingOverlay> createState() =>
      _ChatMascotThinkingOverlayState();
}

class _ChatMascotThinkingOverlayState extends State<ChatMascotThinkingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceProgress;

  late final AnimationController _exitController;
  late final Animation<double> _celebrationProgress;
  late final Animation<double> _sparkleProgress;
  late final Animation<double> _flightProgress;
  late final Animation<double> _landingProgress;

  late final AnimationController _hoverController;
  late final AnimationController _acousticPulseController;

  Timer? _voiceStageTimer;
  Timer? _exitFlightDelayTimer;
  DateTime? _entranceStartTime;
  int _voiceStage = 0; // 0 = listening audio, 1 = analyzing & synthesizing

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _entranceStartTime = DateTime.now();

    // 1. Entrance swoop (~850ms, smooth and well-paced)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _entranceProgress = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // 2. Continuous floating hover bob while thinking in center
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Acoustic wave pulse animation during listening stage
    _acousticPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // 4. Staged Exit Controller (~1280ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1280),
    );

    _celebrationProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.00, 0.42, curve: Curves.easeOut),
      ),
    );

    _sparkleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.04, 0.40, curve: Curves.easeOutBack),
      ),
    );

    _flightProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.38, 0.90, curve: Curves.easeInOutCubic),
      ),
    );

    _landingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.88, 1.00, curve: Curves.easeOutBack),
      ),
    );

    if (widget.isVoiceNote) {
      _voiceStage = 0;
      _voiceStageTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && !_isExiting) {
          setState(() {
            _voiceStage = 1;
          });
        }
      });
    } else {
      _voiceStage = 1;
    }

    _entranceController.forward();
    // Play chewy/bouncy mochi boop sound when mascot pops up on user question
    MascotSoundService().playSound(MascotSoundType.boop);
  }

  @override
  void didUpdateWidget(covariant ChatMascotThinkingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGenerating && !widget.isGenerating && !_isExiting) {
      _voiceStageTimer?.cancel();
      _exitFlightDelayTimer?.cancel();

      final elapsed = DateTime.now().difference(
        _entranceStartTime ?? DateTime.now(),
      );
      const minEntranceStay = Duration(milliseconds: 950);

      if (_entranceController.isAnimating || elapsed < minEntranceStay) {
        final remaining = minEntranceStay - elapsed;
        final waitDuration = remaining.isNegative ? Duration.zero : remaining;
        _exitFlightDelayTimer = Timer(waitDuration, () {
          if (mounted && !_isExiting) {
            _startExitFlight();
          }
        });
      } else {
        _startExitFlight();
      }
    }
  }

  @override
  void dispose() {
    _voiceStageTimer?.cancel();
    _exitFlightDelayTimer?.cancel();
    _entranceController.dispose();
    _hoverController.dispose();
    _acousticPulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _startExitFlight() {
    setState(() {
      _isExiting = true;
    });
    // Play clean pop sound as mascot delivers answer
    MascotSoundService().playSound(MascotSoundType.pop);
    _exitController.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  Offset _calculateTargetOffset(BuildContext context, BoxConstraints constraints) {
    if (widget.targetAvatarGlobalKey != null) {
      final renderBox =
          widget.targetAvatarGlobalKey!.currentContext?.findRenderObject()
              as RenderBox?;
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null &&
          renderBox.hasSize &&
          overlayBox != null &&
          overlayBox.hasSize) {
        final avatarCenterGlobal = renderBox.localToGlobal(
          Offset(renderBox.size.width / 2, renderBox.size.height / 2),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _hoverController,
            _acousticPulseController,
            _exitController,
          ]),
          builder: (context, _) {
            final entrance = _entranceProgress.value;
            final celebrationVal = _celebrationProgress.value;
            final sparkleVal = _sparkleProgress.value;
            final flightVal = _flightProgress.value;
            final landingVal = _landingProgress.value;
            final pulseVal = _acousticPulseController.value;

            final targetOffset = _calculateTargetOffset(context, constraints);
            const startCenterOffset = Offset.zero;

            const startSize = 126.0;
            const targetSize = 40.0;
            const avatarScale = targetSize / startSize;

            final overlayCenter = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            final startEntranceOffset =
                widget.initialPositionInOverlay != null
                ? (widget.initialPositionInOverlay! - overlayCenter)
                : targetOffset;
            final startEntranceScale = widget.initialPositionInOverlay != null
                ? (84.0 / startSize)
                : avatarScale;

            Offset currentOffset;
            double baseScale;
            double bankTilt;
            double flightStretch;
            final clampedEntrance = entrance.clamp(0.0, 1.0);

            if (!_isExiting) {
              // Phase 1: Swooping in from starting position to center
              final arcLift = math.sin(clampedEntrance * math.pi) * 22.0;
              currentOffset = Offset(
                ui.lerpDouble(
                  startEntranceOffset.dx,
                  startCenterOffset.dx,
                  clampedEntrance,
                )!,
                ui.lerpDouble(
                      startEntranceOffset.dy,
                      startCenterOffset.dy,
                      clampedEntrance,
                    )! -
                    arcLift,
              );
              baseScale = ui.lerpDouble(startEntranceScale, 1.0, clampedEntrance)!;
              bankTilt = math.sin(clampedEntrance * math.pi) * 0.16;
              flightStretch = math.sin(clampedEntrance * math.pi) * 0.08;
            } else {
              // Phase 2: Swooping back from center to AppBar avatar slot
              final arcLift = math.sin(flightVal * math.pi) * 36.0;
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

            // Continuous floating hover envelope
            final entranceHoverWeight = ((clampedEntrance - 0.85) / 0.15).clamp(
              0.0,
              1.0,
            );
            final exitHoverWeight = (1.0 - (_exitController.value / 0.15))
                .clamp(0.0, 1.0);
            final hoverWeight = _isExiting
                ? exitHoverWeight
                : entranceHoverWeight;
            final hoverY =
                math.sin(_hoverController.value * 2 * math.pi) *
                4.5 *
                hoverWeight;

            // Joyful "Aha!" celebration double-bounce physics
            double celebrationHopY = 0.0;
            double celebrationSquash = 0.0;
            double celebrationWiggle = 0.0;

            if (_isExiting && flightVal == 0.0 && celebrationVal > 0.0) {
              if (celebrationVal < 0.65) {
                final p = celebrationVal / 0.65;
                celebrationHopY = -math.sin(p * math.pi) * 22.0;
                celebrationSquash = (p < 0.5)
                    ? (math.sin(p * 2 * math.pi) * 0.14)
                    : (-math.sin((p - 0.5) * 2 * math.pi) * 0.16);
              } else {
                final p = (celebrationVal - 0.65) / 0.35;
                celebrationHopY = -math.sin(p * math.pi) * 8.0;
                celebrationSquash = -math.sin(p * math.pi) * 0.08;
              }
              celebrationWiggle =
                  math.sin(celebrationVal * 3.5 * math.pi) * 0.08;
            }

            final mascotTranslateX = currentOffset.dx;
            final mascotTranslateY =
                currentOffset.dy + hoverY + celebrationHopY;

            final landingSquash = (landingVal > 0)
                ? (math.sin(landingVal * math.pi) * 0.07)
                : 0.0;

            final scaleX =
                (baseScale *
                (1.0 -
                    flightStretch * 0.5 -
                    celebrationSquash * 0.6 +
                    landingSquash)).clamp(0.01, 3.0);
            final scaleY =
                (baseScale *
                (1.0 +
                    flightStretch +
                    celebrationSquash +
                    landingSquash * -0.8)).clamp(0.01, 3.0);

            // Frosted Glass Blur & Subtle White Frost
            final activeAlpha = (clampedEntrance * (1.0 - flightVal.clamp(0.0, 1.0))).clamp(
              0.0,
              1.0,
            );
            final currentBlur = (6.5 * activeAlpha).clamp(0.0, 6.5);
            final currentFrost = (0.20 * activeAlpha).clamp(0.0, 0.20);

            // Determine Mascot Mood & Gaze
            ChatMascotMood mascotMood;
            double mascotGazeX;
            final isVoiceListeningStage = widget.isVoiceNote && _voiceStage == 0 && !_isExiting;

            if (_isExiting) {
              if (flightVal > 0.05) {
                mascotMood = ChatMascotMood.idle;
                mascotGazeX = -0.6;
              } else {
                mascotMood = ChatMascotMood.happy;
                mascotGazeX = 0.0;
              }
            } else {
              if (isVoiceListeningStage) {
                mascotMood = ChatMascotMood.listening;
                mascotGazeX = 0.0;
              } else if (entrance < 0.90) {
                mascotMood = ChatMascotMood.idle;
                mascotGazeX = 0.4;
              } else {
                mascotMood = ChatMascotMood.thinking;
                mascotGazeX = 0.0;
              }
            }

            final currentTilt = bankTilt + celebrationWiggle;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Non-cancellable on accidental screen tap
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
                            color: Colors.white.withValues(alpha: currentFrost),
                          ),
                        ),
                      ),
                    ),

                  // 2. Centered Floating Mascot with Thinking / Listening Face Expression
                  Center(
                    child: Transform.translate(
                      offset: Offset(mascotTranslateX, mascotTranslateY),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Concentric Acoustic Soundwaves during Voice Listening Stage
                          if (isVoiceListeningStage)
                            SizedBox.square(
                              dimension: 200,
                              child: CustomPaint(
                                painter: _ThinkingAcousticPainter(
                                  progress: pulseVal,
                                  waveColor: const Color(0xFFF472B6),
                                ),
                              ),
                            ),

                          // Soft warm radiant glow halo when answer is discovered
                          if (sparkleVal > 0.01)
                            Container(
                              width: startSize * (1.0 + sparkleVal * 0.35),
                              height: startSize * (1.0 + sparkleVal * 0.35),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha:
                                          math.sin(sparkleVal * math.pi) *
                                          0.24,
                                    ),
                                    blurRadius: 32,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                          // Mascot Body displaying thinking expression
                          Transform.rotate(
                            angle: currentTilt,
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
                                    isTalking: false,
                                    gazeX: mascotGazeX,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Radiant Vector Sparkle Stars Blooming upon "Aha!"
                          if (sparkleVal > 0.01)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _AnswerSparklesPainter(
                                  progress: sparkleVal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Acoustic wave painter radiating around the mascot during voice note listening stage
class _ThinkingAcousticPainter extends CustomPainter {
  final double progress;
  final Color waveColor;

  const _ThinkingAcousticPainter({
    required this.progress,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const minRadius = 55.0;
    const maxRadius = 95.0;

    for (int i = 0; i < 2; i++) {
      final ringProgress = (progress + (i * 0.5)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * ringProgress;
      final alpha = math.sin(ringProgress * math.pi) * 0.32;

      final paint = Paint()
        ..color = waveColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingAcousticPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter rendering four blooming vector sparkle stars when the answer is found.
class _AnswerSparklesPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  const _AnswerSparklesPainter({required this.progress});

  Path _createStarPath(
    Offset center,
    double outerRadius,
    double innerRadius,
    double rotation,
  ) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = rotation + i * (math.pi / 2);
      final ox = center.dx + outerRadius * math.cos(angle);
      final oy = center.dy + outerRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      final innerAngle = angle + (math.pi / 4);
      final ix = center.dx + innerRadius * math.cos(innerAngle);
      final iy = center.dy + innerRadius * math.sin(innerAngle);
      path.lineTo(ix, iy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01 || progress >= 0.99) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.sin(progress * math.pi);
    final alpha = (math.sin(progress * math.pi) * 0.95).clamp(0.0, 1.0);
    final rotation = progress * 0.6;

    const sparkles = [
      (Offset(48, -48), 9.0, 3.0, AppColors.primary),
      (Offset(-44, -42), 7.5, 2.5, AppColors.primaryLight),
      (Offset(52, -6), 6.0, 2.0, AppColors.primary),
      (Offset(-2, -64), 8.5, 2.8, AppColors.primaryLight),
    ];

    for (final s in sparkles) {
      final currentOffset = center + s.$1 * (0.85 + 0.30 * progress);
      final currentOuter = s.$2 * scale;
      final currentInner = s.$3 * scale;

      // Soft glow blur
      final glowPath = _createStarPath(
        currentOffset,
        currentOuter * 1.5,
        currentInner * 1.5,
        rotation,
      );
      canvas.drawPath(
        glowPath,
        Paint()
          ..color = s.$4.withValues(alpha: alpha * 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Crisp inner diamond star
      final starPath = _createStarPath(
        currentOffset,
        currentOuter,
        currentInner,
        rotation,
      );
      canvas.drawPath(
        starPath,
        Paint()
          ..color = s.$4.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnswerSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
