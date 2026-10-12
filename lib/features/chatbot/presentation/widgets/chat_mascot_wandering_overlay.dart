import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Routine behaviors showcased during interactive wandering in the chat area.
enum _InteractiveRoutine { greeting, dance, question }

/// Floating interactive wandering, bouncing, gesturing & draggable mascot overlay.
///
/// Triggered when the user has been idle on the chat screen for >= 30 seconds
/// or when tapping the mascot avatar in the AppBar.
///
/// Features:
/// 1. **Draggable Anywhere**: The user can drag and move the mascot anywhere in the chat area.
/// 2. **Touch-Aware Expressiveness**: When touched/dragged, the mascot squashes like soft mochi,
///    tilts towards the drag vector, smiles with joyful crescent eyes `^ ^`, and emits a stardust trail.
/// 3. **Asymmetrical Organic Thought Cloud Bubble**: Floating cloud bubble matching the initial greeting popup design.
/// 4. **3 Signature Idle Routines**:
///    - **Menyapa (`ChatMascotMood.greeting`)**: Smiling crescent eyes `^ ^`, two round ball hands (waving right hand), and stardust particle ring.
///    - **Dance (`ChatMascotMood.dance`)**: Rhythmic bouncing and swaying tilt ("mereng kanan-kiri mantul-mantul") with cheerful coral glow.
///    - **Pertanyaan (`ChatMascotMood.question`)**: Tilted quizzical head with circular `?` badge at top-left
///      and thought cloud bubble with clinical inquiry prompts.
/// 5. **Coucou Return Flight**: Smoothly swoops back to the top-left AppBar avatar upon request.
///
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatMascotWanderingOverlay extends StatefulWidget {
  final GlobalKey? targetAvatarGlobalKey;
  final VoidCallback onDismissed;
  final VoidCallback? onUserPromptRequested;
  final ValueChanged<Offset>? onPositionChanged;
  final bool shouldDismiss;

  const ChatMascotWanderingOverlay({
    super.key,
    required this.onDismissed,
    this.targetAvatarGlobalKey,
    this.onUserPromptRequested,
    this.onPositionChanged,
    this.shouldDismiss = false,
  });

  @override
  State<ChatMascotWanderingOverlay> createState() =>
      _ChatMascotWanderingOverlayState();
}

class _ChatMascotWanderingOverlayState extends State<ChatMascotWanderingOverlay>
    with TickerProviderStateMixin {
  static const List<_InteractiveRoutine> _routineSequence = [
    _InteractiveRoutine.greeting,
    _InteractiveRoutine.dance,
    _InteractiveRoutine.question,
  ];

  static const List<String> _thoughtPrompts = [
    'Ada yang ingin kamu tanyakan seputar siklus haidmu?',
    'Mau cek apakah siklus haidmu bulan ini teratur?',
    'Perlu bantuan memahami masa subur atau ovulasi?',
    'Merasa ada gejala atau kram yang tidak biasa?',
    'Ada keluhan seputar PMS yang ingin dikonsultasikan?',
    'Mau catat keluhan fisik hari ini ke jurnal?',
    'Ada pertanyaan seputar kesehatan reproduksimu?',
    'Siap menemani konsultasi medismu hari ini!',
  ];

  late final AnimationController _takeoffController;
  late final Animation<double> _takeoffProgress;

  late final AnimationController _returnController;
  late final Animation<double> _returnProgress;
  late final Animation<double> _landingProgress;

  late final AnimationController _thoughtBubbleController;
  late final Animation<double> _bottomDotProgress;
  late final Animation<double> _middleDotProgress;
  late final Animation<double> _topDotProgress;
  late final Animation<double> _cloudBodyProgress;
  late final Animation<double> _textRevealProgress;

  late final Ticker _wanderTicker;
  final _random = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  bool _isWandering = false;
  bool _isReturning = false;

  // Drag & Touch Interaction States
  bool _isDragging = false;
  double _dragTilt = 0.0;
  double _dragSquash = 0.0;
  double _dragStretch = 0.0;
  double _dragReleaseSpring = 0.0;
  Offset _dragDelta = Offset.zero;

  // Shake & Excessive Drag Physics Engine
  double _shakeEnergy = 0.0;
  double _dizzyTimer = 0.0;
  double _angryTimer = 0.0;
  int _tapCount = 0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDragTimestamp = DateTime.now();
  Offset _previousDragDelta = Offset.zero;

  Offset _currentPos = Offset.zero;
  Offset _targetPos = Offset.zero;
  Offset _velocity = Offset.zero;
  Offset _flightStartPos = Offset.zero;

  int _routineIndex = 0;
  double _routineTimer = 0;
  double _routineDuration = 3.6;
  ChatMascotMood _wanderMood = ChatMascotMood.greeting;
  String _currentThoughtPrompt = _thoughtPrompts[0];

  // Stardust floating particles trail
  final List<_WanderParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // 1. Takeoff from AppBar avatar to first wander position (~620ms)
    _takeoffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _takeoffProgress = CurvedAnimation(
      parent: _takeoffController,
      curve: Curves.easeInOutCubic,
    );

    // 2. Return flight to AppBar avatar slot (~680ms)
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _returnProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _returnController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
      ),
    );
    _landingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _returnController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // 3. Staged Thought Cloud Emergence Animation (~1300ms)
    // Sequence: Bottom Dot -> Middle Dot -> Top Dot -> Cloud Body Expand -> Text Reveal
    _thoughtBubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _bottomDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thoughtBubbleController,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.00, 0.25, curve: Curves.easeInCubic),
      ),
    );
    _middleDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thoughtBubbleController,
        curve: const Interval(0.18, 0.46, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.15, 0.40, curve: Curves.easeInCubic),
      ),
    );
    _topDotProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thoughtBubbleController,
        curve: const Interval(0.34, 0.60, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.30, 0.55, curve: Curves.easeInCubic),
      ),
    );
    _cloudBodyProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thoughtBubbleController,
        curve: const Interval(0.46, 0.82, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.42, 0.78, curve: Curves.easeInCubic),
      ),
    );
    _textRevealProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thoughtBubbleController,
        curve: const Interval(0.78, 1.00, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.75, 1.00, curve: Curves.easeInCubic),
      ),
    );

    _wanderTicker = createTicker(_onWanderTick);

    // Initial takeoff particle burst from AppBar avatar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final avatarPos = _calculateAvatarPosition(context);
      for (int i = 0; i < 8; i++) {
        _particles.add(
          _WanderParticle(
            pos: avatarPos +
                Offset(
                  (_random.nextDouble() - 0.5) * 24,
                  (_random.nextDouble() - 0.5) * 24,
                ),
            alpha: 1.0,
            radius: 2.0 + _random.nextDouble() * 2.5,
            vy: -12.0 - _random.nextDouble() * 15.0,
          ),
        );
      }
    });

    _takeoffController.forward().then((_) {
      if (mounted && !_isReturning) {
        setState(() {
          _isWandering = true;
          _routineIndex = 0; // Start with gentle greeting/wandering (no bubble immediately)
          _applyRoutine(_routineSequence[_routineIndex]);
        });
        _wanderTicker.start();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatMascotWanderingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldDismiss && !oldWidget.shouldDismiss && !_isReturning) {
      _startReturnFlight();
    }
  }

  @override
  void dispose() {
    _wanderTicker.dispose();
    _takeoffController.dispose();
    _returnController.dispose();
    _thoughtBubbleController.dispose();
    super.dispose();
  }

  void _onWanderTick(Duration elapsed) {
    if (_isReturning) return;

    final rawDelta = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = rawDelta.clamp(0.0, 0.04);
    _time += dt;

    // Decay shake energy when not gaining
    if (!_isDragging) {
      _shakeEnergy = math.max(0.0, _shakeEnergy - dt * 14.0);
    }
    // Decay dizzy duration timer
    if (_dizzyTimer > 0) {
      _dizzyTimer = math.max(0.0, _dizzyTimer - dt);
    }
    // Decay angry duration timer
    if (_angryTimer > 0) {
      _angryTimer = math.max(0.0, _angryTimer - dt);
      if (_angryTimer == 0) {
        _tapCount = 0;
        _wanderMood = ChatMascotMood.idle;
      }
    }

    if (_isDragging) {
      // While dragging, decay touch squish slightly into dynamic stretch
      _dragSquash = ui.lerpDouble(_dragSquash, 0.06, 1 - math.exp(-6.0 * dt))!;
      _dragTilt = ui.lerpDouble(_dragTilt, 0.0, 1 - math.exp(-4.0 * dt))!;
      _dragStretch = ui.lerpDouble(_dragStretch, 0.0, 1 - math.exp(-6.0 * dt))!;
    } else {
      _routineTimer += dt;

      // Decay spring bounce & drag deformation after release
      _dragReleaseSpring = math.max(0.0, _dragReleaseSpring - dt * 2.8);
      _dragSquash = ui.lerpDouble(_dragSquash, 0.0, 1 - math.exp(-8.0 * dt))!;
      _dragTilt = ui.lerpDouble(_dragTilt, 0.0, 1 - math.exp(-8.0 * dt))!;
      _dragStretch = ui.lerpDouble(_dragStretch, 0.0, 1 - math.exp(-8.0 * dt))!;

      // 1. Routine State Transition (Greeting -> Dance -> Question -> ...)
      if (_angryTimer <= 0 && _routineTimer >= _routineDuration) {
        _routineTimer = 0.0;
        _routineIndex = (_routineIndex + 1) % _routineSequence.length;
        final nextRoutine = _routineSequence[_routineIndex];
        // Give longer duration to question routine so thought bubble is visible and readable
        _routineDuration = nextRoutine == _InteractiveRoutine.question
            ? (6.8 + _random.nextDouble() * 1.6)
            : (4.0 + _random.nextDouble() * 1.4);
        _applyRoutine(nextRoutine);
        _pickNewWaypoint();
      }

      // 2. Steering force towards target waypoint
      final diff = _targetPos - _currentPos;
      final dist = diff.distance;
      final speedFactor = dist > 40 ? 1.0 : (dist / 40);
      final targetVel = dist > 1
          ? (diff / dist) * (38.0 * speedFactor)
          : Offset.zero;

      // Smooth spring dampening
      _velocity = Offset.lerp(_velocity, targetVel, 1 - math.exp(-3.0 * dt))!;
      _currentPos += _velocity * dt;
    }

    // 3. Update Stardust Floating Trail
    if (_random.nextDouble() < (_isDragging ? 0.65 : 0.28)) {
      _particles.add(
        _WanderParticle(
          pos:
              _currentPos +
              Offset(
                (_random.nextDouble() - 0.5) * (_isDragging ? 32 : 20),
                15 + (_random.nextDouble() - 0.5) * 10,
              ),
          alpha: _isDragging ? 0.95 : 0.7,
          radius: (_isDragging ? 2.0 : 1.5) + _random.nextDouble() * 2.5,
          vy: (_isDragging ? -10.0 : 8.0) + _random.nextDouble() * 14.0,
        ),
      );
    }

    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.alpha -= dt * (_isDragging ? 1.1 : 0.75);
      p.pos = Offset(p.pos.dx, p.pos.dy + p.vy * dt);
      if (p.alpha <= 0) {
        _particles.removeAt(i);
      }
    }

    final hoverBob = _isDragging ? 0.0 : (math.sin(_time * 2.6) * 4.0);
    widget.onPositionChanged?.call(_currentPos + Offset(0, hoverBob));

    setState(() {});
  }

  void _applyRoutine(_InteractiveRoutine routine) {
    if (_isDragging || _angryTimer > 0) return;
    switch (routine) {
      case _InteractiveRoutine.greeting:
        _wanderMood = ChatMascotMood.greeting;
        _thoughtBubbleController.reverse();
        break;
      case _InteractiveRoutine.dance:
        _wanderMood = ChatMascotMood.dance;
        _thoughtBubbleController.reverse();
        break;
      case _InteractiveRoutine.question:
        _wanderMood = ChatMascotMood.question;
        _currentThoughtPrompt =
            _thoughtPrompts[_random.nextInt(_thoughtPrompts.length)];
        Future.delayed(const Duration(milliseconds: 320), () {
          if (mounted &&
              _wanderMood == ChatMascotMood.question &&
              !_isReturning &&
              !_isDragging &&
              _dizzyTimer <= 0 &&
              _angryTimer <= 0) {
            _thoughtBubbleController.forward();
          }
        });
        break;
    }
  }

  void _pickNewWaypoint() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    // Safe bounds in middle-to-lower chat viewport area
    final minX = size.width * 0.20;
    final maxX = size.width * 0.80;
    final minY = size.height * 0.28;
    final maxY = size.height * 0.56;

    _targetPos = Offset(
      minX + _random.nextDouble() * (maxX - minX),
      minY + _random.nextDouble() * (maxY - minY),
    );
  }

  void _handleMascotTap() {
    if (_isReturning) return;
    MascotSoundService().playSound(MascotSoundType.pop);

    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 1400) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    if (_tapCount > 3) {
      _angryTimer = 3.6;
      _wanderMood = ChatMascotMood.angry;
      _thoughtBubbleController.reverse();
      setState(() {});
      return;
    }

    // Quick tap triggers playful routine toggle & cloud speech
    _routineIndex = (_routineIndex + 1) % _routineSequence.length;
    _applyRoutine(_routineSequence[_routineIndex]);
    _routineTimer = 0.0;
  }

  // --- Drag & Touch Interaction Handlers ---

  void _onPanStart(DragStartDetails details) {
    if (_isReturning) return;
    _isDragging = true;
    _lastDragTimestamp = DateTime.now();
    _previousDragDelta = Offset.zero;
    _dragSquash = 0.14; // soft mochi touch pinch
    _dragStretch = 0.0;
    _dragTilt = 0.0;
    _dragReleaseSpring = 0.0;
    _velocity = Offset.zero;
    _thoughtBubbleController.reverse();

    // Burst stardust sparkles on touch
    for (int i = 0; i < 6; i++) {
      _particles.add(
        _WanderParticle(
          pos:
              _currentPos +
              Offset(
                (_random.nextDouble() - 0.5) * 36,
                (_random.nextDouble() - 0.5) * 36,
              ),
          alpha: 1.0,
          radius: 2.2 + _random.nextDouble() * 2.8,
          vy: -12.0 - _random.nextDouble() * 16.0,
        ),
      );
    }

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isReturning) return;

    final now = DateTime.now();
    final dtMs = now.difference(_lastDragTimestamp).inMicroseconds / 1e6;
    _lastDragTimestamp = now;
    final dt = dtMs.clamp(0.008, 0.06);

    _dragDelta = details.delta;
    _currentPos += details.delta;

    // Clamp within visible chat area
    const pad = 44.0;
    final minX = pad;
    final maxX = constraints.maxWidth - pad;
    final minY = 56.0; // below AppBar
    final maxY = constraints.maxHeight - 80.0; // above bottom chat input bar

    _currentPos = Offset(
      _currentPos.dx.clamp(minX, maxX),
      _currentPos.dy.clamp(minY, maxY),
    );

    // Physics Velocity & Shake Detection Engine
    final moveDist = details.delta.distance;
    final instantSpeed = moveDist / dt; // pixels per second

    // Rapid direction reversal check (back-and-forth shake gesture)
    final dot = _previousDragDelta.dx * details.delta.dx +
        _previousDragDelta.dy * details.delta.dy;
    final isDirectionReversal = (dot < -20.0) && (moveDist > 2.5);
    _previousDragDelta = details.delta;

    // Excessive drag / vigorous shaking accumulates shake energy:
    // - Normal gentle drag (speed <= 650 px/s): energy steadily decays
    // - Excessive fast drag (> 800 px/s) or rapid back-and-forth shake: energy builds up
    if (instantSpeed > 800.0 || (isDirectionReversal && instantSpeed > 380.0)) {
      final speedFactor = (instantSpeed / 500.0).clamp(1.0, 3.8);
      final energyGain = (isDirectionReversal ? 6.5 : 2.4) * speedFactor;
      _shakeEnergy += energyGain;
    } else {
      _shakeEnergy = math.max(0.0, _shakeEnergy - 1.5);
    }

    // Trigger dizzy state when shake threshold is crossed
    if (_shakeEnergy >= 22.0) {
      if (_dizzyTimer <= 0.2) {
        MascotSoundService().playSound(MascotSoundType.giggle);
      }
      _dizzyTimer = 2.8; // Mascot stays dizzy for 2.8s
      _shakeEnergy = 0.0;
      _thoughtBubbleController.reverse();
    }

    // Dynamic drag physics deformation & banking tilt
    _dragTilt = (details.delta.dx * 0.045).clamp(-0.35, 0.35);
    _dragStretch = (moveDist * 0.018).clamp(0.0, 0.25);
    _dragSquash = 0.08;

    widget.onPositionChanged?.call(_currentPos);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isReturning) return;

    _isDragging = false;
    final fling = details.velocity.pixelsPerSecond;
    final flingSpeed = fling.distance;
    if (flingSpeed > 1400.0) {
      _shakeEnergy += 12.0;
      if (_shakeEnergy >= 22.0) {
        if (_dizzyTimer <= 0.2) {
          MascotSoundService().playSound(MascotSoundType.giggle);
        }
        _dizzyTimer = 2.8;
        _shakeEnergy = 0.0;
      }
    }

    _velocity = flingSpeed > 50 ? fling * 0.18 : Offset.zero;
    _targetPos = _currentPos;
    _dragReleaseSpring = 0.18; // soft jelly rebound bounce

    setState(() {});
  }

  void _startReturnFlight() {
    if (_isReturning) return;
    _isReturning = true;
    _isDragging = false;
    _wanderTicker.stop();
    _flightStartPos = _currentPos;
    _thoughtBubbleController.reverse();

    setState(() {});

    MascotSoundService().playSound(MascotSoundType.swoop);
    _returnController.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  Offset _calculateAvatarPosition(BuildContext context) {
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
        return avatarCenterGlobal - overlayTopLeftGlobal;
      }
    }
    return const Offset(68.0, 28.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarPos = _calculateAvatarPosition(context);

        if (_currentPos == Offset.zero) {
          _currentPos = avatarPos;
          _targetPos = Offset(
            constraints.maxWidth * 0.50,
            constraints.maxHeight * 0.40,
          );
        }

        Offset renderPos;
        double mascotSize;
        double bankingTilt = 0.0;
        double gazeX = 0.0;
        double scaleX = 1.0;
        double scaleY = 1.0;

        final isDizzy = _dizzyTimer > 0;

        if (_isReturning) {
          // Coucou Bezier Return Flight Arc
          final t = _returnProgress.value;
          final landing = _landingProgress.value;
          final p0 = _flightStartPos;
          final p2 = avatarPos;
          final p1 = Offset(
            p0.dx + (p2.dx - p0.dx) * 0.35,
            math.min(p0.dy, p2.dy) - 60.0,
          );

          final u = 1 - t;
          final flightPos = Offset(
            u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
            u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
          );

          final landingBounce = math.sin(landing * math.pi) * 3.5;
          renderPos = Offset(flightPos.dx, flightPos.dy + landingBounce);

          mascotSize = 84.0 - (84.0 - 40.0) * t;
          bankingTilt = -0.22 * math.sin(t * math.pi);
          gazeX = -0.8;
        } else if (!_isWandering) {
          // Takeoff swoop from AppBar avatar to first wander position
          final t = _takeoffProgress.value;
          final p0 = avatarPos;
          final p2 = _targetPos;
          final p1 = Offset(
            p0.dx + (p2.dx - p0.dx) * 0.65,
            math.max(p0.dy, p2.dy) + 40.0,
          );

          final u = 1 - t;
          renderPos = Offset(
            u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
            u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
          );
          _currentPos = renderPos;
          mascotSize = 40.0 + (84.0 - 40.0) * t;
          bankingTilt = 0.16 * math.sin(t * math.pi);
          gazeX = 0.6;

          // Dynamic takeoff squash, flight stretch & landing mochi bounce
          if (t < 0.18) {
            final prep = math.sin((t / 0.18) * math.pi);
            scaleX = 1.0 + 0.12 * prep;
            scaleY = 1.0 - 0.12 * prep;
          } else if (t < 0.82) {
            scaleX = 0.94;
            scaleY = 1.08;
          } else {
            final landT = (t - 0.82) / 0.18;
            final landBounce = math.sin(landT * math.pi);
            scaleX = 1.0 + 0.14 * landBounce;
            scaleY = 1.0 - 0.14 * landBounce;
          }
        } else if (_isDragging) {
          // Being actively touched & dragged by the user
          renderPos = _currentPos;
          if (isDizzy) {
            final dizzyFactor = (_dizzyTimer / 2.8).clamp(0.0, 1.0);
            renderPos += Offset(
              math.sin(_time * 16.0) * 3.5 * dizzyFactor,
              math.cos(_time * 16.0) * 2.2 * dizzyFactor,
            );
          }
          mascotSize = 92.0; // slightly lifts up towards finger
          bankingTilt = isDizzy ? (math.sin(_time * 14.0) * 0.15) : _dragTilt;
          gazeX = (_dragDelta.dx * 0.12).clamp(-0.9, 0.9);

          // Physical Mochi Touch Squish & Dynamic Pull
          scaleX = 1.0 + _dragSquash - _dragStretch * 0.5;
          scaleY = 1.0 - _dragSquash + _dragStretch;
        } else {
          // Continuous organic wandering & gesturing in chat area
          final hoverBob = math.sin(_time * 2.6) * 4.0;
          renderPos = _currentPos + Offset(0, hoverBob);
          if (isDizzy) {
            final dizzyFactor = (_dizzyTimer / 2.8).clamp(0.0, 1.0);
            renderPos += Offset(
              math.sin(_time * 16.0) * 3.5 * dizzyFactor,
              math.cos(_time * 16.0) * 2.2 * dizzyFactor,
            );
          }
          mascotSize = 84.0;

          bankingTilt = isDizzy
              ? (math.sin(_time * 14.0) * 0.15)
              : (_velocity.dx / 120.0).clamp(-0.24, 0.24);
          gazeX = (_velocity.dx / 60.0).clamp(-0.85, 0.85);

          // Spring release settle bounce
          scaleX = 1.0 + _dragReleaseSpring * 0.8;
          scaleY = 1.0 - _dragReleaseSpring * 0.9;
        }

        return Stack(
          children: [
            // Stardust particle trail (IgnorePointer so touches pass freely to chat)
            IgnorePointer(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ParticleTrailPainter(_particles),
              ),
            ),

            // Roaming & Draggable Mascot Component with Touch-Aware Expressions
            Positioned(
              left: renderPos.dx - mascotSize / 2,
              top: renderPos.dy - mascotSize / 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleMascotTap,
                onPanStart: _onPanStart,
                onPanUpdate: (details) => _onPanUpdate(details, constraints),
                onPanEnd: _onPanEnd,
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  child: Transform.rotate(
                    angle: bankingTilt,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Radiant Ambient Glow Aura while being held / dragged
                        if (_isDragging)
                          Container(
                            width: mascotSize * 1.35,
                            height: mascotSize * 1.35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.32),
                                  AppColors.primarySoft.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                        // Living Mochi Mascot
                        ChatMascot(
                          size: mascotSize,
                          mood: _isReturning
                              ? ChatMascotMood.idle
                              : (_angryTimer > 0
                                    ? ChatMascotMood.angry
                                    : (isDizzy
                                          ? ChatMascotMood.dizzy
                                          : (_isDragging
                                                ? ChatMascotMood.dance
                                                : _wanderMood))),
                          gazeX: gazeX,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Asymmetrical Organic Thought Cloud Bubble matching greeting popup design
            if (_isWandering &&
                !_isReturning &&
                !_isDragging &&
                !isDizzy &&
                _angryTimer <= 0)
              _buildOrganicCloudThoughtBubble(
                constraints,
                renderPos,
                mascotSize,
              ),
          ],
        );
      },
    );
  }

  /// Renders the asymmetrical organic thought cloud bubble positioned above the roaming mascot
  Widget _buildOrganicCloudThoughtBubble(
    BoxConstraints constraints,
    Offset mascotCenter,
    double mascotSize,
  ) {
    const bubbleWidth = 254.0;
    final bubbleLeft = math.max(
      12.0,
      math.min(
        constraints.maxWidth - bubbleWidth - 12.0,
        mascotCenter.dx - bubbleWidth * 0.45,
      ),
    );
    final bubbleTop = math.max(50.0, mascotCenter.dy - mascotSize / 2 - 118.0);

    return AnimatedBuilder(
      animation: _thoughtBubbleController,
      builder: (context, child) {
        if (_thoughtBubbleController.value <= 0.001) {
          return const SizedBox.shrink();
        }

        final cloudScale = _cloudBodyProgress.value;
        final textOpacity = _textRevealProgress.value;
        final textSlideY = (1.0 - _textRevealProgress.value) * 6.0;

        return Positioned(
          left: bubbleLeft,
          top: bubbleTop,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onUserPromptRequested?.call();
              _thoughtBubbleController.reverse();
            },
            child: SizedBox(
              width: bubbleWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Organic Asymmetrical Thought Cloud Body (scales from tail connection point)
                  Transform.scale(
                    scale: cloudScale,
                    alignment: const Alignment(0.48, 1.0),
                    child: Opacity(
                      opacity: cloudScale.clamp(0.0, 1.0),
                      child: CustomPaint(
                        painter: _AsymmetricThoughtCloudPainter(
                          fillColor: AppColors.cardBackground,
                          borderColor: AppColors.primarySoft,
                          borderWidth: 1.5,
                          shadowColor: AppColors.primary.withValues(
                            alpha: 0.18,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 22, 14),
                          child: Center(
                            child: Opacity(
                              opacity: textOpacity.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, textSlideY),
                                child: Text(
                                  _currentThoughtPrompt,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    height: 1.42,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Staged Thought Bubble Dots emerging progressively from bottom up to cloud
                  _buildThoughtTail(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Descending thought tail dots emerging sequentially from bottom to top towards the cloud
  Widget _buildThoughtTail() {
    final topVal = _topDotProgress.value;
    final midVal = _middleDotProgress.value;
    final botVal = _bottomDotProgress.value;

    return Padding(
      padding: const EdgeInsets.only(right: 48, top: 3),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Top dot (largest, closest to cloud right pocket)
            Transform.scale(
              scale: topVal,
              child: Opacity(
                opacity: topVal.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Middle dot
            Transform.scale(
              scale: midVal,
              child: Opacity(
                opacity: midVal.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  width: 7.5,
                  height: 7.5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Bottom dot (smallest, closest to mascot's head)
            Transform.scale(
              scale: botVal,
              child: Opacity(
                opacity: botVal.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(right: 28),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primarySoft, width: 0.9),
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

/// Custom painter rendering the unique, ASYMMETRICAL thought cloud matching the opening popup
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

    path.moveTo(w * 0.10, h * 0.22);

    // 1. Top Edge: Left buoyant puff, dynamic mid puff, and sloped right puff
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
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Crisp subtle drop shadow
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x0E000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
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

class _WanderParticle {
  Offset pos;
  double alpha;
  double radius;
  double vy;

  _WanderParticle({
    required this.pos,
    required this.alpha,
    required this.radius,
    required this.vy,
  });
}

class _ParticleTrailPainter extends CustomPainter {
  final List<_WanderParticle> particles;

  _ParticleTrailPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.alpha <= 0) continue;
      canvas.drawCircle(
        p.pos,
        p.radius,
        Paint()
          ..color = AppColors.primarySoft.withValues(alpha: p.alpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        p.pos,
        p.radius * 0.7,
        Paint()..color = Colors.white.withValues(alpha: p.alpha * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleTrailPainter oldDelegate) => true;
}
