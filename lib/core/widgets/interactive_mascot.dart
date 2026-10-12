import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/services/mascot_sound_service.dart';

/// Interactive Mascot component with dynamic breathing, bounce animations,
/// expressive speech bubbles, floating heart particles, and cute sound effects.
class InteractiveMascot extends StatefulWidget {
  final double width;
  final double height;
  final String imagePath;
  final bool showSpeechBubbleOnTap;
  final VoidCallback? onCustomTap;

  const InteractiveMascot({
    super.key,
    this.width = 140,
    this.height = 140,
    this.imagePath = 'assets/Komponen/komponenOrang.png',
    this.showSpeechBubbleOnTap = true,
    this.onCustomTap,
  });

  @override
  State<InteractiveMascot> createState() => _InteractiveMascotState();
}

class _InteractiveMascotState extends State<InteractiveMascot>
    with TickerProviderStateMixin {
  // Idle breathing animation controller
  late final AnimationController _idleController;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _tiltAnimation;

  // Interaction reaction bounce controller
  late final AnimationController _reactionController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _jumpAnimation;

  // Speech bubble & particles state
  String? _currentSpeech;
  Timer? _speechTimer;
  final List<_MascotParticle> _particles = [];
  final math.Random _random = math.Random();

  static const List<String> _cuteDialogues = [
    'Hai! Semangat ya hari ini!',
    'Jangan lupa minum air yang cukup!',
    'Kamu hebat dan sangat berharga!',
    'Istirahat yang nyaman ya hari ini!',
    'Tubuhmu bekerja luar biasa!',
    'Senyum dulu yuk, kamu cantik!',
    'Aku selalu siap menemanimu!',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Setup Idle Floating & Swaying Animation
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    _tiltAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 2. Setup Reaction Bounce & Squish Animation with silky spring damping
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.94).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 36,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 36,
      ),
    ]).animate(_reactionController);

    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -16.0, end: 2.5).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 2.5, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_reactionController);
  }

  void _triggerTapInteraction() {
    // 1. Play bounce animation & sound
    _reactionController.forward(from: 0.0);
    MascotSoundService().playSound(MascotSoundType.pop);

    // 2. Spawn floating heart particles
    _spawnParticles(count: 3);

    // 3. Show cute encouraging speech bubble
    if (widget.showSpeechBubbleOnTap) {
      final text = _cuteDialogues[_random.nextInt(_cuteDialogues.length)];
      _showSpeech(text);
    }

    widget.onCustomTap?.call();
  }

  void _triggerDoubleTapInteraction() {
    // 1. Play intense reaction bounce & sound
    _reactionController.forward(from: 0.0);
    MascotSoundService().playSound(MascotSoundType.happy);

    // 2. Spawn celebratory heart shower
    _spawnParticles(count: 6);

    // 3. Show cheerful double-tap dialogue
    if (widget.showSpeechBubbleOnTap) {
      _showSpeech('Yeay! Senang bisa menemanimu!');
    }
  }

  void _triggerLongPressInteraction() {
    // 1. Reaction animation & sound
    _reactionController.forward(from: 0.0);
    MascotSoundService().playSound(MascotSoundType.giggle);

    // 2. Particles
    _spawnParticles(count: 4);

    // 3. Show shy giggle dialogue
    if (widget.showSpeechBubbleOnTap) {
      _showSpeech('Hehe, geli! Makasih sudah menyapaku!');
    }
  }

  void _showSpeech(String text) {
    _speechTimer?.cancel();
    setState(() {
      _currentSpeech = text;
    });

    _speechTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _currentSpeech = null;
        });
      }
    });
  }

  void _spawnParticles({required int count}) {
    for (int i = 0; i < count; i++) {
      final particle = _MascotParticle(
        startX: (widget.width * 0.4) + (_random.nextDouble() * 30 - 15),
        startY: widget.height * 0.3,
        driftX: (_random.nextDouble() - 0.5) * 35,
        driftY: -45 - (_random.nextDouble() * 25),
        size: 14 + (_random.nextDouble() * 8),
        icon: _random.nextBool() ? Icons.favorite_rounded : Icons.auto_awesome_rounded,
        color: _random.nextBool() ? AppColors.primary : const Color(0xFFFF85A1),
      );

      setState(() {
        _particles.add(particle);
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _particles.remove(particle);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _idleController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width + 40,
      height: widget.height + 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Speech Bubble Pop-up above mascot
          if (_currentSpeech != null)
            Positioned(
              top: -24,
              right: 10,
              child: _SpeechBubble(text: _currentSpeech!),
            ),

          // Floating particles (hearts / sparkles)
          ..._particles.map((p) => _ParticleWidget(particle: p)),

          // Animated Mascot
          AnimatedBuilder(
            animation: Listenable.merge([_idleController, _reactionController]),
            builder: (context, child) {
              final idleFloat = _floatingAnimation.value;
              final idleTilt = _tiltAnimation.value;
              final reactionScale = _scaleAnimation.value;
              final reactionJump = _jumpAnimation.value;

              return Transform.translate(
                offset: Offset(0, idleFloat + reactionJump),
                child: Transform.rotate(
                  angle: idleTilt,
                  child: Transform.scale(
                    scale: reactionScale,
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: _triggerTapInteraction,
              onDoubleTap: _triggerDoubleTapInteraction,
              onLongPress: _triggerLongPressInteraction,
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Speech Bubble with animated entry fade and soft shadow.
class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomRight,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MascotParticle {
  final double startX;
  final double startY;
  final double driftX;
  final double driftY;
  final double size;
  final IconData icon;
  final Color color;

  _MascotParticle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.driftY,
    required this.size,
    required this.icon,
    required this.color,
  });
}

class _ParticleWidget extends StatelessWidget {
  final _MascotParticle particle;

  const _ParticleWidget({required this.particle});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        final currentX = particle.startX + (particle.driftX * value);
        final currentY = particle.startY + (particle.driftY * value);
        final opacity = (1.0 - value).clamp(0.0, 1.0);
        final scale = 0.5 + (0.5 * (1.0 - (value - 0.5).abs() * 2));

        return Positioned(
          left: currentX,
          top: currentY,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                particle.icon,
                size: particle.size,
                color: particle.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
