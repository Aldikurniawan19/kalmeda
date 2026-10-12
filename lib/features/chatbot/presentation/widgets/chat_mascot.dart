import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';

/// Emotional and behavioral states of the Coucou Mochi companion.
enum ChatMascotMood {
  greeting,
  working,
  thinking,
  question,
  finished,
  dance,
  idle,
  listening,
  happy, // Alias of finished/dance for backward compatibility
  dizzy, // Dizzy/dazed state triggered by excessive shaking or rapid dragging
  angry, // Angry/pouting state triggered by >3 consecutive taps
}

/// Timing constants (in seconds) for the mascot's procedural animation engine.
abstract class _MascotTiming {
  static const double blinkDuration = 0.16;
  static const double blinkMinGap = 2.2;
  static const double blinkGapRange = 3.0;
  static const double lookMinGap = 1.4;
  static const double lookGapRange = 2.2;
  static const double jumpDuration = 0.62;
  static const double breathPeriod = 3.2;
  static const double thinkingScanSpeed = 1.4;
  static const double thinkingTiltSpeed = 1.6;
  static const double thinkingHoverSpeed = 3.0;
  static const double workingScanSpeed = 3.5;
  static const double smoothing = 8.5; // Optimized for silk-smooth organic expression transitions
  static const double maxFrameDelta = 0.05;
  static const double centerLookChance = 0.35;
}

/// Coucou Mochi Character Implementation:
///
/// Mathematical specifications from Coucou (Louis-CFM/coucou):
/// - Superellipse body geometry: |x/rx|^2.7 + |y/ry|^2.7 = 1 (rx = 1.14 R, ry = 0.88 R)
/// - Solid black bead dot eyes on sphere (yaw ±0.37 rx, pitch -0.12 ry)
/// - Soft 3D specular highlight at (0.34 rx, -0.46 ry) with radius 0.42 R
/// - Soft pastel rosy blush at outer flanks
///
/// State-Specific Visual Designs & Smooth Transitions:
/// 1. **Greeting**: White squircle tilted with smiling crescent eyes `^ ^`, two round ball hands (raised right wave + lower left), and subtle ambient particle ring.
/// 2. **Thinking**: Purple/violet ambient glow, solid black dot eyes looking thoughtful, and top-left capsule badge with pulsing `...` ellipsis.
/// 3. **Question**: Cyan/blue ambient glow, tilted head, solid black dot eyes, and top-left circular badge with `?` mark.
/// 4. **Finished**: Mint/emerald green ambient glow, smiling crescent eyes `^ ^`, top-left green status badge, and 3 sparkling diamond stars above head.
/// 5. **Dance**: Spontaneous cute rhythmic bouncing and swaying left and right every 10 seconds (or on `ChatMascotMood.dance`) with smiling crescent eyes `^ ^`.
/// 6. **Working**: Amber/rose ambient glow, focused dot eyes, and top-left working activity indicator.
/// 7. **Dizzy**: Soft violet glow, spinning spiral eyes `@ @`, orbiting diamond stars above head, wobbly tilt, and wavy dazed mouth `~`.
/// 8. **Angry**: Crimson/rose warm hue, quivering vibration, furrowed slanted eyes `\ /`, pouting mouth, and procedural 4-point comic anger vein mark on the temple.
/// 9. **Idle / Listening**: Clean minimalist Mochi with breathing, spontaneous blinking, and caret/gaze tracking.
class ChatMascot extends StatefulWidget {
  final double size;
  final ChatMascotMood mood;
  final bool isTalking;

  /// Horizontal gaze target in range -1..1, used while [ChatMascotMood.listening].
  final double gazeX;

  /// Optional custom body colors (e.g. for Home screen theme)
  final Color? customTopColor;
  final Color? customBottomColor;
  final Color? customGlowColor;

  /// Whether tapping the mascot >3 times in rapid succession triggers the angry expression (only active when [onTap] or gesture handling is enabled)
  final bool enableAngryOnTap;

  /// Optional custom tap callback
  final VoidCallback? onTap;

  /// Notifies when the mascot enters or exits the angry state
  final ValueChanged<bool>? onAngryChanged;

  const ChatMascot({
    super.key,
    required this.size,
    this.mood = ChatMascotMood.idle,
    this.isTalking = false,
    this.gazeX = 0,
    this.customTopColor,
    this.customBottomColor,
    this.customGlowColor,
    this.enableAngryOnTap = false,
    this.onTap,
    this.onAngryChanged,
  });

  @override
  State<ChatMascot> createState() => _ChatMascotState();
}

class _ChatMascotState extends State<ChatMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _random = math.Random();
  final _pose = ValueNotifier<_MascotPose>(const _MascotPose());

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _nextBlinkAt = 1.2;
  double _blinkStart = -1;
  double _nextLookAt = 0;
  double _jumpStart = -10;
  Offset _idleLookTarget = Offset.zero;

  Offset _gaze = Offset.zero;
  double _lid = 0;
  double _happy = 0;
  double _tilt = 0;
  double _hover = 0;

  // Tap tracking for angry reaction (>3 consecutive taps)
  int _tapCount = 0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _internalAngry = false;
  Timer? _angryCooldownTimer;

  // Continuous expression & feature morphing channels
  double _handsProgress = 0.0;
  double _blushProgress = 0.0;
  double _thinkingProgress = 0.0;
  double _questionProgress = 0.0;
  double _finishedProgress = 0.0;
  double _workingProgress = 0.0;
  double _dizzyProgress = 0.0;
  double _angryProgress = 0.0;

  // Continuous color gradient morphing channels
  Color _bodyMidColor = const Color(0xFFEDEDF2);
  Color _bodyBottomColor = const Color(0xFF888896);
  Color _glowColor = Colors.white;
  double _glowOpacity = 0.18;

  @override
  void initState() {
    super.initState();
    if (widget.mood == ChatMascotMood.happy ||
        widget.mood == ChatMascotMood.finished ||
        widget.mood == ChatMascotMood.dance ||
        widget.mood == ChatMascotMood.greeting) {
      _jumpStart = 0;
      _happy = 1.0;
    }

    final (initMid, initBottom, initGlow, initGlowAlpha) = _targetColors(
      widget.mood,
      0.0,
    );
    _bodyMidColor = initMid;
    _bodyBottomColor = initBottom;
    _glowColor = initGlow;
    _glowOpacity = initGlowAlpha;
    _handsProgress = widget.mood == ChatMascotMood.greeting ? 1.0 : 0.0;
    _blushProgress = widget.mood == ChatMascotMood.greeting ? 1.0 : 0.0;
    _thinkingProgress = widget.mood == ChatMascotMood.thinking ? 1.0 : 0.0;
    _questionProgress = widget.mood == ChatMascotMood.question ? 1.0 : 0.0;
    _finishedProgress = widget.mood == ChatMascotMood.finished ? 1.0 : 0.0;
    _workingProgress = widget.mood == ChatMascotMood.working ? 1.0 : 0.0;
    _dizzyProgress = widget.mood == ChatMascotMood.dizzy ? 1.0 : 0.0;
    _angryProgress = widget.mood == ChatMascotMood.angry ? 1.0 : 0.0;

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant ChatMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      if (widget.mood == ChatMascotMood.happy ||
          widget.mood == ChatMascotMood.finished) {
        _jumpStart = _time;
      } else if (widget.mood == ChatMascotMood.dizzy) {
        MascotSoundService().playSound(MascotSoundType.giggle);
      }
    }
  }

  @override
  void dispose() {
    _angryCooldownTimer?.cancel();
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  void _handleTap() {
    MascotSoundService().playSound(MascotSoundType.pop);
    widget.onTap?.call();
    if (!widget.enableAngryOnTap) return;

    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 1400) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    if (_tapCount > 3) {
      _triggerAngry();
    }
  }

  void _triggerAngry() {
    _angryCooldownTimer?.cancel();
    setState(() {
      _internalAngry = true;
    });
    widget.onAngryChanged?.call(true);

    _angryCooldownTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        setState(() {
          _internalAngry = false;
          _tapCount = 0;
        });
        widget.onAngryChanged?.call(false);
      }
    });
  }

  (Color, Color, Color, double) _targetColors(
    ChatMascotMood mood,
    double danceEnvelope,
  ) {
    if (widget.customGlowColor != null ||
        widget.customTopColor != null ||
        widget.customBottomColor != null) {
      final mid = widget.customBottomColor != null
          ? Color.lerp(
              widget.customTopColor ?? Colors.white,
              widget.customBottomColor!,
              0.45,
            )!
          : const Color(0xFFEDEDF2);
      final bottom = widget.customBottomColor ?? const Color(0xFF888896);
      final glow = widget.customGlowColor ?? Colors.white;
      return (mid, bottom, glow, 0.32);
    }

    if (danceEnvelope > 0.01) {
      return (
        const Color(0xFFEDEDF2),
        const Color(0xFF888896),
        const Color(0xFFEF4444),
        (0.35 * danceEnvelope).clamp(0.0, 0.40),
      );
    }

    final effectiveMood = _internalAngry ? ChatMascotMood.angry : mood;

    switch (effectiveMood) {
      case ChatMascotMood.angry:
        return (
          const Color(0xFFFFF1F2), // Soft blush rose top
          const Color(0xFFFECDD3), // Warm rose mid
          const Color(0xFFF43F5E), // Fiery crimson base
          0.45,                    // Radiant red aura
        );
      case ChatMascotMood.thinking:
        return (
          const Color(0xFFF3E8FF),
          const Color(0xFFD8B4FE),
          const Color(0xFFA855F7),
          0.35,
        );
      case ChatMascotMood.question:
        return (
          const Color(0xFFE0F2FE),
          const Color(0xFFBAE6FD),
          const Color(0xFF06B6D4),
          0.35,
        );
      case ChatMascotMood.finished:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF10B981),
          0.38,
        );
      case ChatMascotMood.working:
        return (
          const Color(0xFFFFF1F2),
          AppColors.primarySoft,
          AppColors.primary,
          0.32,
        );
      case ChatMascotMood.dance:
        return (
          const Color(0xFFEDEDF2),
          const Color(0xFF888896),
          const Color(0xFFEF4444),
          0.35,
        );
      case ChatMascotMood.dizzy:
        return (
          const Color(0xFFF5F3FF),
          const Color(0xFFDDD6FE),
          const Color(0xFFA855F7),
          0.32,
        );
      case ChatMascotMood.greeting:
      case ChatMascotMood.idle:
      case ChatMascotMood.listening:
      case ChatMascotMood.happy:
        return (
          const Color(0xFFEDEDF2),
          const Color(0xFF888896),
          Colors.white,
          0.18,
        );
    }
  }
  void _onTick(Duration elapsed) {
    final rawDelta = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = rawDelta.clamp(0.0, _MascotTiming.maxFrameDelta);
    _time += dt;

    final ease = 1 - math.exp(-_MascotTiming.smoothing * dt);
    final mood = widget.mood;
    final effectiveMood = _internalAngry ? ChatMascotMood.angry : mood;

    final isHappyState =
        !_internalAngry &&
        (mood == ChatMascotMood.happy ||
            mood == ChatMascotMood.finished ||
            mood == ChatMascotMood.dance ||
            mood == ChatMascotMood.greeting);

    final targetHappy = isHappyState ? 1.0 : 0.0;

    _gaze = Offset.lerp(_gaze, _targetGaze(effectiveMood), ease)!;

    double targetLid = 0.0;
    if (effectiveMood == ChatMascotMood.thinking) {
      targetLid = 0.35;
    } else if (effectiveMood == ChatMascotMood.working) {
      targetLid = 0.15;
    } else if (effectiveMood == ChatMascotMood.angry) {
      targetLid = 0.05;
    }
    _lid = _lerp(_lid, targetLid, ease);

    _happy = _lerp(_happy, targetHappy, ease * 0.85);
    _tilt = _lerp(_tilt, _targetTilt(effectiveMood), ease);
    _hover = _lerp(_hover, _targetHover(effectiveMood), ease);

    // Continuous feature & prop progress interpolation
    final targetHands =
        (effectiveMood == ChatMascotMood.greeting && !_internalAngry) ? 1.0 : 0.0;
    final targetBlush =
        (effectiveMood == ChatMascotMood.greeting && !_internalAngry) ? 1.0 : 0.0;
    final targetThinking =
        (effectiveMood == ChatMascotMood.thinking && !_internalAngry) ? 1.0 : 0.0;
    final targetQuestion =
        (effectiveMood == ChatMascotMood.question && !_internalAngry) ? 1.0 : 0.0;
    final targetFinished =
        (effectiveMood == ChatMascotMood.finished && !_internalAngry) ? 1.0 : 0.0;
    final targetWorking =
        (effectiveMood == ChatMascotMood.working && !_internalAngry) ? 1.0 : 0.0;
    final targetDizzy =
        (effectiveMood == ChatMascotMood.dizzy && !_internalAngry) ? 1.0 : 0.0;
    final targetAngry =
        (effectiveMood == ChatMascotMood.angry || _internalAngry) ? 1.0 : 0.0;

    _handsProgress = _lerp(_handsProgress, targetHands, ease * 0.75);
    _blushProgress = _lerp(_blushProgress, targetBlush, ease * 0.75);
    _thinkingProgress = _lerp(_thinkingProgress, targetThinking, ease * 0.85);
    _questionProgress = _lerp(_questionProgress, targetQuestion, ease * 0.85);
    _finishedProgress = _lerp(_finishedProgress, targetFinished, ease * 0.85);
    _workingProgress = _lerp(_workingProgress, targetWorking, ease * 0.85);
    _dizzyProgress = _lerp(_dizzyProgress, targetDizzy, ease * 0.85);
    _angryProgress = _lerp(_angryProgress, targetAngry, ease * 0.85);

    // Continuous 3D gradient color blending
    final (targetMid, targetBottom, targetGlow, targetGlowAlpha) =
        _targetColors(effectiveMood, 0.0);
    _bodyMidColor = Color.lerp(_bodyMidColor, targetMid, ease * 0.65)!;
    _bodyBottomColor = Color.lerp(_bodyBottomColor, targetBottom, ease * 0.65)!;
    _glowColor = Color.lerp(_glowColor, targetGlow, ease * 0.65)!;
    _glowOpacity = _lerp(_glowOpacity, targetGlowAlpha, ease * 0.65);

    _pose.value = _MascotPose(
      gaze: _gaze,
      lid: math.max(_lid, _blinkAmount()),
      happy: _happy,
      tilt: _tilt,
      breath: math.sin(2 * math.pi * _time / _MascotTiming.breathPeriod),
      lift: _jumpLift(effectiveMood),
      stretch: _jumpStretch(effectiveMood),
      hover: _hover,
      isTalking: widget.isTalking,
      time: _time,
      mood: effectiveMood,
      handsProgress: _handsProgress,
      blushProgress: _blushProgress,
      thinkingProgress: _thinkingProgress,
      questionProgress: _questionProgress,
      finishedProgress: _finishedProgress,
      workingProgress: _workingProgress,
      dizzyProgress: _dizzyProgress,
      angryProgress: _angryProgress,
      bodyMidColor: _bodyMidColor,
      bodyBottomColor: _bodyBottomColor,
      glowColor: _glowColor,
      glowOpacity: _glowOpacity,
      customTopColor: widget.customTopColor,
      customBottomColor: widget.customBottomColor,
      customGlowColor: widget.customGlowColor,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Offset _targetGaze(ChatMascotMood mood) {
    switch (mood) {
      case ChatMascotMood.angry:
        return const Offset(0.0, -0.08);
      case ChatMascotMood.greeting:
      case ChatMascotMood.finished:
      case ChatMascotMood.dance:
      case ChatMascotMood.happy:
        return Offset.zero;
      case ChatMascotMood.dizzy:
        return Offset(
          0.50 * math.cos(_time * 6.5),
          0.50 * math.sin(_time * 6.5),
        );
      case ChatMascotMood.listening:
        return Offset(widget.gazeX.clamp(-1.0, 1.0), 0.6);
      case ChatMascotMood.thinking:
        return Offset(
          0.5 * math.sin(_time * _MascotTiming.thinkingScanSpeed),
          -0.55,
        );
      case ChatMascotMood.working:
        return Offset(
          0.3 * math.sin(_time * _MascotTiming.workingScanSpeed),
          0.35,
        );
      case ChatMascotMood.question:
        return const Offset(0.20, -0.30);
      case ChatMascotMood.idle:
        if (_time >= _nextLookAt) {
          final lookCenter =
              _random.nextDouble() < _MascotTiming.centerLookChance;
          _idleLookTarget = lookCenter
              ? Offset.zero
              : Offset(
                  _random.nextDouble() * 2 - 1,
                  _random.nextDouble() * 1.4 - 0.7,
                );
          _nextLookAt =
              _time +
              _MascotTiming.lookMinGap +
              _random.nextDouble() * _MascotTiming.lookGapRange;
        }
        return _idleLookTarget;
    }
  }

  double _targetTilt(ChatMascotMood mood) {
    switch (mood) {
      case ChatMascotMood.angry:
        return math.sin(_time * 28.0) * 0.045;
      case ChatMascotMood.greeting:
        return 0.12;
      case ChatMascotMood.dizzy:
        return math.sin(_time * 14.0) * 0.16;
      case ChatMascotMood.thinking:
        return 0.05 * math.sin(_time * _MascotTiming.thinkingTiltSpeed);
      case ChatMascotMood.working:
        return 0.03 * math.sin(_time * 6.0);
      case ChatMascotMood.question:
        return -0.10;
      case ChatMascotMood.dance:
      case ChatMascotMood.listening:
      case ChatMascotMood.idle:
      case ChatMascotMood.finished:
      case ChatMascotMood.happy:
        return 0;
    }
  }

  double _targetHover(ChatMascotMood mood) {
    if (mood == ChatMascotMood.angry) {
      return 0.016 * (math.sin(_time * 14.0).abs() - 0.5);
    }
    if (mood == ChatMascotMood.thinking || mood == ChatMascotMood.question) {
      return 0.025 * (1 + math.sin(_time * _MascotTiming.thinkingHoverSpeed));
    }
    if (mood == ChatMascotMood.dizzy) {
      return 0.012 * math.sin(_time * 8.0);
    }
    return 0.0;
  }

  double _blinkAmount() {
    if (_blinkStart < 0 && _time >= _nextBlinkAt) {
      _blinkStart = _time;
    }
    if (_blinkStart < 0) return 0;

    final progress = (_time - _blinkStart) / _MascotTiming.blinkDuration;
    if (progress >= 1) {
      _blinkStart = -1;
      _nextBlinkAt =
          _time +
          _MascotTiming.blinkMinGap +
          _random.nextDouble() * _MascotTiming.blinkGapRange;
      return 0;
    }
    return math.sin(math.pi * progress);
  }

  double _jumpLift(ChatMascotMood mood) {
    final p = (_time - _jumpStart) / _MascotTiming.jumpDuration;
    if (p < 0 || p >= 1) return 0;
    return math.sin(math.pi * p);
  }

  double _jumpStretch(ChatMascotMood mood) {
    final p = (_time - _jumpStart) / _MascotTiming.jumpDuration;
    if (p < 0 || p >= 1) return 0;
    if (p < 0.5) return 0.08 * math.sin(math.pi * p * 2);
    return -0.1 * math.sin(math.pi * (p - 0.5) * 2);
  }

  @override
  Widget build(BuildContext context) {
    final mascotWidget = RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _MascotPainter(_pose)),
      ),
    );

    if (widget.onTap != null || widget.enableAngryOnTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: mascotWidget,
      );
    }

    return mascotWidget;
  }
}

/// Immutable snapshot of the mascot pose for a single frame.
class _MascotPose {
  final Offset gaze;
  final double lid;
  final double happy;
  final double tilt;
  final double breath;
  final double lift;
  final double stretch;
  final double hover;
  final bool isTalking;
  final double time;
  final ChatMascotMood mood;

  // Continuous feature channels
  final double handsProgress;
  final double blushProgress;
  final double thinkingProgress;
  final double questionProgress;
  final double finishedProgress;
  final double workingProgress;
  final double dizzyProgress;
  final double angryProgress;

  // Continuous color gradient channels
  final Color bodyMidColor;
  final Color bodyBottomColor;
  final Color glowColor;
  final double glowOpacity;

  final Color? customTopColor;
  final Color? customBottomColor;
  final Color? customGlowColor;

  const _MascotPose({
    this.gaze = Offset.zero,
    this.lid = 0,
    this.happy = 0,
    this.tilt = 0,
    this.breath = 0,
    this.lift = 0,
    this.stretch = 0,
    this.hover = 0,
    this.isTalking = false,
    this.time = 0,
    this.mood = ChatMascotMood.idle,
    this.handsProgress = 0,
    this.blushProgress = 0,
    this.thinkingProgress = 0,
    this.questionProgress = 0,
    this.finishedProgress = 0,
    this.workingProgress = 0,
    this.dizzyProgress = 0,
    this.angryProgress = 0,
    this.bodyMidColor = const Color(0xFFEDEDF2),
    this.bodyBottomColor = const Color(0xFF888896),
    this.glowColor = Colors.white,
    this.glowOpacity = 0.18,
    this.customTopColor,
    this.customBottomColor,
    this.customGlowColor,
  });
}

class _MascotPainter extends CustomPainter {
  final ValueNotifier<_MascotPose> pose;

  _MascotPainter(this.pose) : super(repaint: pose);

  /// Builds the Coucou superellipse: |x/rx|^2.7 + |y/ry|^2.7 = 1
  Path _buildSuperellipse(double rx, double ry, {int segments = 80}) {
    final path = Path();
    const p = 2.0 / 2.7; // ~0.74074074
    for (int i = 0; i <= segments; i++) {
      final theta = (i / segments) * 2 * math.pi;
      final cosT = math.cos(theta);
      final sinT = math.sin(theta);
      final signX = cosT >= 0 ? 1.0 : -1.0;
      final signY = sinT >= 0 ? 1.0 : -1.0;
      final x = rx * signX * math.pow(cosT.abs(), p);
      final y = ry * signY * math.pow(sinT.abs(), p);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose.value;
    final w = size.width;

    // Blueprint parameters:
    // rx = 1.14 R, ry = 0.88 R, where R ~ w * 0.41
    final r = w * 0.41;
    final rx = 1.14 * r;
    final ry = 0.88 * r;
    final groundY = size.height * 0.92;
    final lift = (p.lift * 0.16 + p.hover) * w;

    // 1. Soft Ground Shadow
    _paintShadow(
      canvas,
      Offset(w / 2, groundY),
      rx,
      w,
      (lift / w),
    );

    final totalStretch = p.stretch;
    final angryJitterX = p.angryProgress > 0.005
        ? math.sin(p.time * 36.0) * (2.4 * p.angryProgress)
        : 0.0;
    final angryPuff = p.angryProgress > 0.005
        ? math.sin(p.time * 12.0) * (0.04 * p.angryProgress)
        : 0.0;

    final sy = (1 + totalStretch) * (1 + p.breath * 0.025) - angryPuff * 0.5;
    final sx = 1 - totalStretch * 0.8 - p.breath * 0.012 + angryPuff;

    canvas.save();
    final mascotCenter = Offset(w / 2 + angryJitterX, groundY - ry - lift);
    canvas.translate(mascotCenter.dx, mascotCenter.dy);
    canvas.rotate(p.tilt);
    canvas.scale(sx, sy);

    final mood = p.mood;

    // 2. State-Themed Ambient Under-Glow
    _paintAmbientGlow(canvas, rx, ry, p);

    // 3. Greeting State: Ball Hands emerging smoothly from BEHIND flanks
    if (p.handsProgress > 0.005) {
      _paintGreetingHands(canvas, rx, ry, p);
    }

    // 4. Superellipse Body (|x/rx|^2.7 + |y/ry|^2.7 = 1) with liquid color morphing
    _paintMochiBody(canvas, rx, ry, r, p);

    // 5. Rosy Cheek Blush (Smoothly fades with blushProgress or angryProgress)
    if (p.blushProgress > 0.005 || p.angryProgress > 0.005) {
      _paintBlush(canvas, rx, ry, p);
    }

    // 6. Eyes (Smooth continuous morphing between dot eyes, crescent smiles, and dizzy spirals)
    _paintEyes(canvas, rx, ry, p, mood);

    // 7. Mouth (Dazed when dizzy, Angry Pout, or Greeting/Speaking)
    if (p.dizzyProgress > 0.005) {
      _paintDizzyMouth(canvas, rx, ry, p);
    } else if (p.angryProgress > 0.005) {
      _paintAngryMouth(canvas, rx, ry, p);
    } else if (p.mood == ChatMascotMood.greeting || p.isTalking) {
      _paintSpeakingMouth(canvas, rx, ry, p);
    }

    // 9. State-Specific Badges & Sparkles (Smooth pop-in / fade-out)
    if (p.thinkingProgress > 0.005) {
      _paintThinkingBadge(canvas, rx, ry, p);
    }
    if (p.questionProgress > 0.005) {
      _paintQuestionBadge(canvas, rx, ry, p);
    }
    if (p.finishedProgress > 0.005) {
      _paintFinishedBadgeAndSparkles(canvas, rx, ry, p);
    }
    if (p.workingProgress > 0.005) {
      _paintWorkingBadge(canvas, rx, ry, p);
    }
    if (p.dizzyProgress > 0.005) {
      _paintDizzyStars(canvas, rx, ry, p);
    }
    if (p.angryProgress > 0.005) {
      _paintAngerMark(canvas, rx, ry, p);
    }

    canvas.restore();
  }

  void _paintShadow(
    Canvas canvas,
    Offset center,
    double rx,
    double w,
    double liftNorm,
  ) {
    final scale = (1 - liftNorm * 0.45).clamp(0.0, 1.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: rx * 1.55 * scale,
        height: w * 0.07 * scale,
      ),
      Paint()..color = AppColors.chatMascotShadow,
    );
  }

  /// Ambient colored glow beneath/around the mascot matching each Coucou state
  void _paintAmbientGlow(Canvas canvas, double rx, double ry, _MascotPose p) {
    Color glowColor = p.customGlowColor ?? p.glowColor;
    double glowRadius = rx * 1.45;
    double glowOpacity = p.glowOpacity;

    // Soft blurred radial ambient aura
    canvas.drawCircle(
      Offset(0, ry * 0.2),
      glowRadius,
      Paint()
        ..color = glowColor.withValues(alpha: glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Greeting particle star dust ring
    if (p.handsProgress > 0.005) {
      _paintGreetingParticleRing(canvas, rx, ry, p.time, p.handsProgress);
    }
  }

  /// Ambient stardust particle ring in Greeting state
  void _paintGreetingParticleRing(
    Canvas canvas,
    double rx,
    double ry,
    double time,
    double alphaProgress,
  ) {
    const particleCount = 28;
    final ringRadiusX = rx * 1.42;
    final ringRadiusY = ry * 1.30;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + (time * 0.15);
      final distNoise = math.sin(i * 99 + time * 2) * 6.0;
      final px = (ringRadiusX + distNoise) * math.cos(angle);
      final py = (ringRadiusY + distNoise) * math.sin(angle);
      final pAlpha = (0.20 + 0.35 * math.sin(i * 37 + time * 3)).clamp(
        0.0,
        0.7,
      ) * alphaProgress;
      final pSize = 1.0 + (i % 3) * 0.8;

      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = Colors.white.withValues(alpha: pAlpha),
      );
    }
  }

  /// White/tinted Mochi body (|x/rx|^2.7 + |y/ry|^2.7 = 1) with 3D specular volume
  void _paintMochiBody(
    Canvas canvas,
    double rx,
    double ry,
    double r,
    _MascotPose p,
  ) {
    final bodyPath = _buildSuperellipse(rx, ry);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );

    // Rich 3D volumetric gradient with smooth color morphing
    Color topColor = p.customTopColor ?? Colors.white;
    Color midColor = p.customBottomColor != null
        ? Color.lerp(topColor, p.customBottomColor!, 0.45)!
        : p.bodyMidColor;
    Color bottomColor = p.customBottomColor ?? p.bodyBottomColor;

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, midColor, bottomColor],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    // Blueprint 3D Specular Highlight: (.34 rx, -.46 ry) · radius .44 R
    canvas.save();
    canvas.clipPath(bodyPath);
    final specCenter = Offset(0.34 * rx, -0.46 * ry);
    final specRadius = 0.44 * r;
    canvas.drawCircle(
      specCenter,
      specRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          specCenter,
          specRadius,
          [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
          [0.0, 0.50, 1.0],
        ),
    );
    canvas.restore();
  }

  void _paintBlush(
    Canvas canvas,
    double rx,
    double ry,
    _MascotPose p,
  ) {
    final effectiveProgress = math.max(p.blushProgress, p.angryProgress * 0.90);
    final bp = effectiveProgress.clamp(0.0, 1.0);
    if (bp <= 0.005) return;

    final baseBlush = const Color(0xFFFDA4AF); // Soft Coucou blush pink
    final angryBlush = const Color(0xFFF43F5E); // Fiery hot angry blush
    final blushColor = p.angryProgress > 0.02
        ? Color.lerp(baseBlush, angryBlush, p.angryProgress)!
        : baseBlush;

    final paint = Paint()
      ..color = blushColor.withValues(
        alpha: (0.70 + 0.20 * p.angryProgress) * bp,
      );

    final scale = 0.5 + 0.5 * math.sin(bp * math.pi / 2);

    // Blueprint Blush: outer flanks below eyes
    for (final side in const [-1.0, 1.0]) {
      final center = Offset(side * 0.58 * rx, 0.16 * ry);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: rx * (0.22 + 0.06 * p.angryProgress) * scale,
          height: ry * (0.12 + 0.04 * p.angryProgress) * scale,
        ),
        paint,
      );
    }
  }

  /// Eyes: Continuous smooth morphing between solid bead dots, smiling crescent curves `^ ^`, spinning dizzy spirals `@ @`, and angry furrowed glare `\ /`
  void _paintEyes(
    Canvas canvas,
    double rx,
    double ry,
    _MascotPose p,
    ChatMascotMood mood,
  ) {
    final eyeR = ry * 0.14; // Blueprint bead size
    final happyVal = p.happy.clamp(0.0, 1.0);
    final dizzyVal = p.dizzyProgress.clamp(0.0, 1.0);
    final angryVal = p.angryProgress.clamp(0.0, 1.0);

    for (final side in const [-1.0, 1.0]) {
      final baseCenter = Offset(side * 0.37 * rx, -0.06 * ry);

      final dx = p.gaze.dx * (1.0 - happyVal * 0.8);
      final dy = p.gaze.dy * (1.0 - happyVal * 0.8);
      final sphericalZ = math.sqrt(
        (1.0 - dx * dx * 0.25 - dy * dy * 0.25).clamp(0.1, 1.0),
      );

      final eyeCenter = baseCenter.translate(
        dx * rx * 0.18 * sphericalZ,
        dy * ry * 0.18 * sphericalZ,
      );

      double effectiveLid = p.lid;
      if (mood == ChatMascotMood.question && side > 0) {
        effectiveLid = math.max(0.0, effectiveLid - 0.15); // Quizzical eye
      }

      final openness = (1.0 - effectiveLid).clamp(0.08, 1.0);

      // Normal bead eye fades out when happy or dizzy
      final dotAlpha = ((1.0 - happyVal) * (1.0 - dizzyVal)).clamp(0.0, 1.0);
      if (dotAlpha > 0.01) {
        final dotHeight = eyeR * 2 * openness * (1.0 - happyVal * 0.65);
        canvas.drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: eyeR * 2,
            height: dotHeight,
          ),
          Paint()..color = const Color(0xFF1E1E24).withValues(alpha: dotAlpha),
        );

        // Sharp angry furrowed eyebrows \ / drawn over the bead eye
        if (angryVal > 0.005) {
          _paintAngryEyebrow(canvas, eyeCenter, eyeR, side < 0, angryVal);
        }
      }

      // Happy Crescent Eye `^ ^` (fades out when dizzy or angry)
      final smileAlpha = (happyVal * (1.0 - dizzyVal) * (1.0 - angryVal)).clamp(
        0.0,
        1.0,
      );
      if (smileAlpha > 0.01) {
        final archHeight = eyeR * (0.35 + 0.80 * happyVal);
        final path = Path()
          ..moveTo(
            eyeCenter.dx - eyeR * 1.20,
            eyeCenter.dy + eyeR * 0.40 * (1.0 - happyVal * 0.2),
          )
          ..quadraticBezierTo(
            eyeCenter.dx,
            eyeCenter.dy - archHeight,
            eyeCenter.dx + eyeR * 1.20,
            eyeCenter.dy + eyeR * 0.40 * (1.0 - happyVal * 0.2),
          );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1E1E24).withValues(alpha: smileAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = eyeR * (0.45 + 0.20 * happyVal)
            ..strokeCap = StrokeCap.round,
        );
      }

      // Spinning Spiral Eye `@ @` when dizzy
      if (dizzyVal > 0.005) {
        _paintSpiralEye(
          canvas,
          eyeCenter,
          eyeR * 1.15,
          side > 0, // Left clockwise, right counter-clockwise
          p.time,
          dizzyVal,
        );
      }
    }
  }

  /// Sharp furrowed angry eyebrow stroke slanting downward towards nose bridge \ /
  void _paintAngryEyebrow(
    Canvas canvas,
    Offset eyeCenter,
    double eyeR,
    bool isLeft,
    double progress,
  ) {
    final ap = progress.clamp(0.0, 1.0);
    final browPath = Path();

    if (isLeft) {
      // Left brow slants down-right \
      browPath.moveTo(
        eyeCenter.dx - eyeR * 1.30,
        eyeCenter.dy - eyeR * 1.10,
      );
      browPath.quadraticBezierTo(
        eyeCenter.dx - eyeR * 0.10,
        eyeCenter.dy - eyeR * 0.70,
        eyeCenter.dx + eyeR * 1.05,
        eyeCenter.dy - eyeR * 0.15,
      );
    } else {
      // Right brow slants down-left /
      browPath.moveTo(
        eyeCenter.dx + eyeR * 1.30,
        eyeCenter.dy - eyeR * 1.10,
      );
      browPath.quadraticBezierTo(
        eyeCenter.dx + eyeR * 0.10,
        eyeCenter.dy - eyeR * 0.70,
        eyeCenter.dx - eyeR * 1.05,
        eyeCenter.dy - eyeR * 0.15,
      );
    }

    canvas.drawPath(
      browPath,
      Paint()
        ..color = const Color(0xFF1E1E24).withValues(alpha: ap)
        ..style = PaintingStyle.stroke
        ..strokeWidth = eyeR * 0.52
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Cute clenched downturned pouting mouth when angry
  void _paintAngryMouth(Canvas canvas, double rx, double ry, _MascotPose p) {
    final ap = p.angryProgress.clamp(0.0, 1.0);
    if (ap <= 0.005) return;

    final mouthCenter = Offset(0, 0.16 * ry);
    final mouthW = rx * 0.17;
    final poutH = ry * 0.038;

    final path = Path()
      ..moveTo(mouthCenter.dx - mouthW / 2, mouthCenter.dy + poutH * 0.5)
      ..quadraticBezierTo(
        mouthCenter.dx,
        mouthCenter.dy - poutH,
        mouthCenter.dx + mouthW / 2,
        mouthCenter.dy + poutH * 0.5,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1E1E24).withValues(alpha: ap)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.034
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Procedural vector comic anger vein mark on temple
  void _paintAngerMark(Canvas canvas, double rx, double ry, _MascotPose p) {
    final progress = p.angryProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final markCenter = Offset(rx * 0.54, -ry * 0.60);
    final markSize = rx * 0.30;

    canvas.save();
    canvas.translate(markCenter.dx, markCenter.dy);
    final scale = (0.88 + 0.14 * math.sin(p.time * 13.0)) *
        math.sin(progress * math.pi / 2);
    canvas.scale(scale, scale);

    final half = markSize / 2;
    final inset = markSize * 0.18;
    final curveD = markSize * 0.12;

    final path = Path();

    // Top-Right bracket ⮑
    path.moveTo(inset, -half);
    path.quadraticBezierTo(inset + curveD, -inset - curveD, half, -inset);

    // Top-Left bracket ⮐
    path.moveTo(-inset, -half);
    path.quadraticBezierTo(-inset - curveD, -inset - curveD, -half, -inset);

    // Bottom-Left bracket ⮎
    path.moveTo(-inset, half);
    path.quadraticBezierTo(-inset - curveD, inset + curveD, -half, inset);

    // Bottom-Right bracket ⮏
    path.moveTo(inset, half);
    path.quadraticBezierTo(inset + curveD, inset + curveD, half, inset);

    // Outer white halo for contrast & pop
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = markSize * 0.28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Crimson Anger Vein Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE11D48).withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = markSize * 0.18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  /// Procedural spinning Archimedean spiral eye
  void _paintSpiralEye(
    Canvas canvas,
    Offset center,
    double maxRadius,
    bool isClockwise,
    double time,
    double alpha,
  ) {
    final a = alpha.clamp(0.0, 1.0);
    if (a <= 0.005) return;

    final spiralPath = Path();
    const turns = 2.2;
    const totalAngle = turns * 2 * math.pi;
    const steps = 44;
    final spinAngle = time * 7.5 * (isClockwise ? 1.0 : -1.0);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final currentTheta = t * totalAngle;
      final currentR = t * maxRadius;
      final finalAngle = currentTheta * (isClockwise ? 1.0 : -1.0) + spinAngle;
      final x = center.dx + currentR * math.cos(finalAngle);
      final y = center.dy + currentR * math.sin(finalAngle);

      if (i == 0) {
        spiralPath.moveTo(x, y);
      } else {
        spiralPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      spiralPath,
      Paint()
        ..color = const Color(0xFF1E1E24).withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxRadius * 0.26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Cute wavy dazed mouth `~` when dizzy
  void _paintDizzyMouth(Canvas canvas, double rx, double ry, _MascotPose p) {
    final progress = p.dizzyProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final mouthCenter = Offset(0, 0.16 * ry);
    final mouthW = rx * 0.20;
    final waveAmp = ry * 0.038 * (0.8 + 0.2 * math.sin(p.time * 10.0));

    final path = Path()
      ..moveTo(mouthCenter.dx - mouthW / 2, mouthCenter.dy)
      ..cubicTo(
        mouthCenter.dx - mouthW / 4,
        mouthCenter.dy - waveAmp,
        mouthCenter.dx - mouthW / 8,
        mouthCenter.dy + waveAmp,
        mouthCenter.dx,
        mouthCenter.dy,
      )
      ..cubicTo(
        mouthCenter.dx + mouthW / 8,
        mouthCenter.dy - waveAmp,
        mouthCenter.dx + mouthW / 4,
        mouthCenter.dy + waveAmp,
        mouthCenter.dx + mouthW / 2,
        mouthCenter.dy,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1E1E24).withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.032
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Orbiting 3D diamond cartoon stars above mascot head when dizzy
  void _paintDizzyStars(
    Canvas canvas,
    double rx,
    double ry,
    _MascotPose p,
  ) {
    final progress = p.dizzyProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    const starCount = 3;
    final orbitCenter = Offset(0, -ry * 0.98);
    final orbitRadiusX = rx * 0.72;
    final orbitRadiusY = ry * 0.22;

    for (int i = 0; i < starCount; i++) {
      final baseAngle = (i / starCount) * 2 * math.pi;
      final currentAngle = baseAngle + (p.time * 4.2);

      final starX = orbitCenter.dx + orbitRadiusX * math.cos(currentAngle);
      final starY = orbitCenter.dy + orbitRadiusY * math.sin(currentAngle);

      final sinVal = math.sin(currentAngle);
      final depthScale = 0.75 + 0.35 * (sinVal + 1.0) / 2.0;
      final starAlpha =
          ((0.55 + 0.45 * (sinVal + 1.0) / 2.0) * progress).clamp(0.0, 1.0);
      final starSize = 9.5 * depthScale * progress;

      _paintDiamondStar(
        canvas,
        Offset(starX, starY),
        starSize,
        starAlpha,
      );
    }
  }

  void _paintSpeakingMouth(Canvas canvas, double rx, double ry, _MascotPose p) {
    // Only open mouth when greeting (awal buka aplikasi / greeting state) or in chat screen talking (isTalking)
    final isAllowed = p.mood == ChatMascotMood.greeting || p.isTalking;
    if (!isAllowed) return;

    final center = Offset(p.gaze.dx * rx * 0.04, 0.14 * ry);
    final speechWave = p.isTalking
        ? (math.sin(p.time * 13.0).abs() * 0.62 +
                math.sin(p.time * 6.5).abs() * 0.38)
            .clamp(0.12, 1.0)
        : (p.mood == ChatMascotMood.greeting
            ? (math.sin(p.time * 8.5).abs() * 0.55 + 0.15).clamp(0.10, 0.85)
            : 0.0);
    final vocalOpen = speechWave;
    if (vocalOpen <= 0.005) return;

    final mouthH = math.max(0.5, ry * (0.04 + 0.11 * vocalOpen));
    final mouthW = math.max(0.5, rx * (0.11 + 0.09 * vocalOpen));

    final rect = Rect.fromCenter(center: center, width: mouthW, height: mouthH);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(mouthH / 2));

    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E1E24));

    if (mouthH > ry * 0.07) {
      canvas.save();
      canvas.clipRRect(rrect);
      final tongueRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + mouthH * 0.32),
        width: math.max(0.5, mouthW * 0.85),
        height: math.max(0.5, mouthH * 0.65),
      );
      canvas.drawOval(
        tongueRect,
        Paint()..color = const Color(0xFFFDA4AF).withValues(alpha: 0.90),
      );
      canvas.restore();
    }
  }

  // --- COUCOU STATE-SPECIFIC PROPS & BADGES ---

  /// Greeting: Two 3D organic ball-limb hands emerging smoothly from BEHIND side-rear flanks
  void _paintGreetingHands(Canvas canvas, double rx, double ry, _MascotPose p) {
    final hp = p.handsProgress.clamp(0.0, 1.0);
    if (hp <= 0.005) return;

    final waveBob = math.sin(p.time * 6.5) * 2.8;
    final waveTilt = math.sin(p.time * 6.5) * 0.10;

    final topColor = p.customTopColor ?? Colors.white;
    final bottomColor = p.customBottomColor ?? p.bodyBottomColor;

    // Smooth ease-out extension curve for hands emerging from behind flanks
    final reach = math.sin(hp * math.pi / 2);

    final rightRoot = Offset(rx * 0.72, ry * 0.02);
    final rightTargetTip = Offset(rx * 1.03, -ry * 0.10 + waveBob);
    final rightTip = Offset.lerp(rightRoot, rightTargetTip, reach)!;

    final leftRoot = Offset(-rx * 0.72, ry * 0.26);
    final leftTargetTip = Offset(-rx * 1.01, ry * 0.38 - waveBob * 0.3);
    final leftTip = Offset.lerp(leftRoot, leftTargetTip, reach)!;

    // 1. Right Hand (raised waving 3D limb)
    _paintOrganic3DHandLimb(
      canvas,
      rootPos: rightRoot,
      tipPos: rightTip,
      rootRadius: rx * 0.21 * (0.4 + 0.6 * reach),
      tipRadius: rx * 0.19 * (0.4 + 0.6 * reach),
      topColor: topColor,
      bottomColor: bottomColor,
      isRightHand: true,
      tilt: waveTilt * reach,
      alpha: hp,
    );

    // 2. Left Hand (resting 3D limb)
    _paintOrganic3DHandLimb(
      canvas,
      rootPos: leftRoot,
      tipPos: leftTip,
      rootRadius: rx * 0.20 * (0.4 + 0.6 * reach),
      tipRadius: rx * 0.18 * (0.4 + 0.6 * reach),
      topColor: topColor,
      bottomColor: bottomColor,
      isRightHand: false,
      tilt: -waveTilt * 0.35 * reach,
      alpha: hp,
    );
  }

  /// Paints a continuous 3D limb starting from deep behind the body out to a spherical ball tip
  void _paintOrganic3DHandLimb(
    Canvas canvas, {
    required Offset rootPos,
    required Offset tipPos,
    required double rootRadius,
    required double tipRadius,
    required Color topColor,
    required Color bottomColor,
    required bool isRightHand,
    double tilt = 0.0,
    double alpha = 1.0,
  }) {
    final a = alpha.clamp(0.0, 1.0);
    if (a <= 0.005) return;

    canvas.save();

    final delta = tipPos - rootPos;
    final angle = math.atan2(delta.dy, delta.dx);
    final normal = Offset(-math.sin(angle), math.cos(angle));

    final safeRootRadius = math.max(0.1, rootRadius);
    final safeTipRadius = math.max(0.1, tipRadius);

    final p1 = rootPos + normal * safeRootRadius;
    final p2 = tipPos + normal * safeTipRadius;
    final p3 = tipPos - normal * safeTipRadius;
    final p4 = rootPos - normal * safeRootRadius;

    // Organic capsule hull connecting root inside/behind the body to outer ball tip
    final limbPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..arcToPoint(
        p3,
        radius: Radius.circular(safeTipRadius),
        clockwise: isRightHand,
      )
      ..lineTo(p4.dx, p4.dy)
      ..close();

    // 1. Ambient depth shadow behind the limb
    canvas.drawPath(
      limbPath.shift(Offset(0, tipRadius * 0.18)),
      Paint()
        ..color = const Color(0x22000000).withValues(alpha: 0.13 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // 2. Main 3D volumetric gradient fill along the limb
    final limbBounds = limbPath.getBounds();
    canvas.drawPath(
      limbPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: a),
            topColor.withValues(alpha: a),
            bottomColor.withValues(alpha: a),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(limbBounds),
    );

    // 3. Spherical 3D ball tip volume with radial lighting from top-front
    final lightOffset = tipPos + Offset(-tipRadius * 0.28, -tipRadius * 0.30);
    canvas.drawCircle(
      tipPos,
      tipRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          lightOffset,
          tipRadius * 1.35,
          [
            Colors.white.withValues(alpha: a),
            topColor.withValues(alpha: a),
            bottomColor.withValues(alpha: a),
          ],
          [0.0, 0.45, 1.0],
        ),
    );

    // 4. Subtle outer depth silhouette stroke
    canvas.drawPath(
      limbPath,
      Paint()
        ..color = const Color(0x18000000).withValues(alpha: 0.10 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 5. Specular Highlight on spherical ball tip
    final specRadius = tipRadius * 0.45;
    canvas.drawCircle(
      lightOffset,
      specRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          lightOffset,
          specRadius,
          [
            Colors.white.withValues(alpha: 0.85 * a),
            Colors.white.withValues(alpha: 0.28 * a),
            Colors.white.withValues(alpha: 0.0),
          ],
          [0.0, 0.45, 1.0],
        ),
    );

    canvas.restore();
  }

  /// Thinking: Capsule badge with thick black border and purple fill with 3 white dots `...`
  void _paintThinkingBadge(Canvas canvas, double rx, double ry, _MascotPose p) {
    final progress = p.thinkingProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final badgeCenter = Offset(-rx * 0.55, -ry * 0.72);
    final badgeWidth = rx * 0.62;
    final badgeHeight = ry * 0.34;

    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    final scale = math.sin(progress * math.pi / 2);
    canvas.scale(scale, scale);

    final badgeRect = Rect.fromCenter(
      center: Offset.zero,
      width: badgeWidth,
      height: badgeHeight,
    );
    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(badgeHeight / 2),
    );

    // Thick black outer border
    canvas.drawRRect(
      badgeRRect,
      Paint()..color = const Color(0xFF1E1E24).withValues(alpha: progress),
    );

    // Purple fill
    final innerRRect = RRect.fromRectAndRadius(
      badgeRect.deflate(2.2),
      Radius.circular((badgeHeight - 4.4) / 2),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()..color = const Color(0xFFA855F7).withValues(alpha: progress),
    );

    // 3 pulsing white dots `...`
    final dotRadius = badgeHeight * 0.12;
    final dotSpacing = badgeWidth * 0.22;
    for (int i = 0; i < 3; i++) {
      final dotX = (i - 1) * dotSpacing;
      final dotY = 0.0;
      final phase = (p.time * 4.0 - i * 0.8);
      final dotAlpha =
          (0.40 + 0.60 * math.sin(phase).abs()).clamp(0.2, 1.0) * progress;

      canvas.drawCircle(
        Offset(dotX, dotY),
        dotRadius,
        Paint()..color = Colors.white.withValues(alpha: dotAlpha),
      );
    }
    canvas.restore();
  }

  /// Question: Circular badge with thick black border and cyan fill with white `?`
  void _paintQuestionBadge(Canvas canvas, double rx, double ry, _MascotPose p) {
    final progress = p.questionProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final badgeCenter = Offset(-rx * 0.55, -ry * 0.72);
    final badgeRadius = ry * 0.28;

    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    final scale = math.sin(progress * math.pi / 2);
    canvas.scale(scale, scale);

    // Thick black outer border
    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()..color = const Color(0xFF1E1E24).withValues(alpha: progress),
    );

    // Cyan fill
    canvas.drawCircle(
      Offset.zero,
      badgeRadius - 2.2,
      Paint()..color = const Color(0xFF06B6D4).withValues(alpha: progress),
    );

    // Vector "?" mark
    final qPath = Path()
      ..moveTo(
        -badgeRadius * 0.32,
        -badgeRadius * 0.22,
      )
      ..cubicTo(
        -badgeRadius * 0.32,
        -badgeRadius * 0.60,
        badgeRadius * 0.36,
        -badgeRadius * 0.60,
        badgeRadius * 0.30,
        -badgeRadius * 0.15,
      )
      ..cubicTo(
        badgeRadius * 0.24,
        badgeRadius * 0.12,
        0.0,
        badgeRadius * 0.12,
        0.0,
        badgeRadius * 0.28,
      );

    canvas.drawPath(
      qPath,
      Paint()
        ..color = Colors.white.withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = badgeRadius * 0.24
        ..strokeCap = StrokeCap.round,
    );

    // Question mark bottom dot
    canvas.drawCircle(
      Offset(0.0, badgeRadius * 0.52),
      badgeRadius * 0.12,
      Paint()..color = Colors.white.withValues(alpha: progress),
    );

    canvas.restore();
  }

  /// Finished: Green status badge at top-left + 3 sparkling stars above head
  void _paintFinishedBadgeAndSparkles(
    Canvas canvas,
    double rx,
    double ry,
    _MascotPose p,
  ) {
    final progress = p.finishedProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final badgeCenter = Offset(-rx * 0.55, -ry * 0.72);
    final badgeRadius = ry * 0.22;

    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    final scale = math.sin(progress * math.pi / 2);
    canvas.scale(scale, scale);

    // 1. Top-Left Green Status Dot
    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()..color = const Color(0xFF1E1E24).withValues(alpha: progress),
    );
    canvas.drawCircle(
      Offset.zero,
      badgeRadius - 2.2,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: progress),
    );
    canvas.restore();

    // 2. 3 Sparkling Diamond Stars above head
    final stars = [
      (Offset(-rx * 0.30, -ry * 1.05), 10.0, 0.0), // Left star
      (Offset(rx * 0.05, -ry * 1.25), 13.0, 1.2), // Center/Top star
      (Offset(rx * 0.40, -ry * 1.00), 8.5, 2.4), // Right star
    ];

    for (final s in stars) {
      final pos = s.$1;
      final baseSize = s.$2;
      final phaseOffset = s.$3;

      final phase = p.time * 4.5 + phaseOffset;
      final sScale = (0.70 + 0.35 * math.sin(phase)).clamp(0.3, 1.15) * scale;
      final sAlpha = (0.65 + 0.35 * math.sin(phase)).clamp(0.4, 1.0) * progress;

      _paintDiamondStar(canvas, pos, baseSize * sScale, sAlpha);
    }
  }

  /// Vector 4-point diamond star (✦)
  void _paintDiamondStar(
    Canvas canvas,
    Offset center,
    double size,
    double alpha,
  ) {
    final path = Path();
    final half = size / 2;

    path.moveTo(center.dx, center.dy - half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    path.close();

    // Soft glow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Crisp star
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }

  /// Working: Amber/Orange activity badge at top-left
  void _paintWorkingBadge(Canvas canvas, double rx, double ry, _MascotPose p) {
    final progress = p.workingProgress.clamp(0.0, 1.0);
    if (progress <= 0.005) return;

    final badgeCenter = Offset(-rx * 0.55, -ry * 0.72);
    final badgeRadius = ry * 0.24;

    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    final scale = math.sin(progress * math.pi / 2);
    canvas.scale(scale, scale);

    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()..color = const Color(0xFF1E1E24).withValues(alpha: progress),
    );
    canvas.drawCircle(
      Offset.zero,
      badgeRadius - 2.2,
      Paint()..color = AppColors.primary.withValues(alpha: progress),
    );

    // Rotating mini activity arc
    final sweepAngle = math.pi * 1.2;
    final startAngle = p.time * 8.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: badgeRadius * 0.55),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.pose != pose;
}
