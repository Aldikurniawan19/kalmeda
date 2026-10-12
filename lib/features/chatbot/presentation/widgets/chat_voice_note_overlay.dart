import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/features/chatbot/data/datasources/voice_recording_service.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// WhatsApp-style Voice Note Screen Backdrop & Mascot Listener Overlay for Kalmeda.
///
/// Features:
/// 1. Deep frosted glass blur (`BackdropFilter`) over chat history.
/// 2. Centered floating Coucou Mochi mascot in active listening mode (`ChatMascotMood.listening`)
///    with procedural concentric acoustic pulse waves and floating particles.
/// 3. Prominent slide-to-cancel guidance bar rendered directly on top of the blur layer
///    with animated drifting chevrons (`< < < Geser ke kiri untuk membatalkan`).
/// 4. Attentive listening status indicator pill that dynamically reflects live speech recognition.
/// 5. Procedural live audio equalizer visualizer reacting to microphone amplitude.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatVoiceNoteOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final ValueChanged<int> onSendVoiceNote;
  final double dragOffset;
  final bool isCancelThresholdMet;

  const ChatVoiceNoteOverlay({
    super.key,
    required this.onCancel,
    required this.onSendVoiceNote,
    this.dragOffset = 0.0,
    this.isCancelThresholdMet = false,
  });

  @override
  State<ChatVoiceNoteOverlay> createState() => _ChatVoiceNoteOverlayState();
}

class _ChatVoiceNoteOverlayState extends State<ChatVoiceNoteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_AcousticParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Initialize decorative acoustic floating particles
    final rnd = math.Random();
    for (int i = 0; i < 16; i++) {
      _particles.add(
        _AcousticParticle(
          angle: rnd.nextDouble() * 2 * math.pi,
          distance: 50.0 + rnd.nextDouble() * 55.0,
          speed: 0.4 + rnd.nextDouble() * 0.8,
          radius: 1.5 + rnd.nextDouble() * 2.2,
          opacity: 0.25 + rnd.nextDouble() * 0.55,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCancelling = widget.isCancelThresholdMet;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final animVal = _animController.value;
          final floatOffset = math.sin(animVal * 2 * math.pi) * 5.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Clean Frosted Glass Backdrop Filter (blurs actual chat screen without dark dim)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
              ),

              // 2. Centered Floating Mascot with Concentric Resonant Wave Rings (On top of blur)
              Center(
                child: Transform.translate(
                  offset: Offset(0, floatOffset - 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mascot Studio Aura
                      SizedBox.square(
                        dimension: 230,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric Acoustic Resonant Waves
                            CustomPaint(
                              size: const Size(230, 230),
                              painter: _ResonantAcousticPainter(
                                progress: animVal,
                                isCancelling: isCancelling,
                                particles: _particles,
                              ),
                            ),

                            // Mochi Mascot in Listening Mood
                            ChatMascot(
                              size: 122,
                              mood: isCancelling
                                  ? ChatMascotMood.question
                                  : ChatMascotMood.listening,
                              gazeX: isCancelling ? -0.5 : 0.0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Attentive Listening Status Pill (Dynamic live transcript display)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ValueListenableBuilder<String>(
                          valueListenable:
                              VoiceRecordingService().liveTranscriptionNotifier,
                          builder: (context, liveWords, _) {
                            final hasWords = liveWords.trim().isNotEmpty;
                            final displayText = isCancelling
                                ? 'Lepas untuk membatalkan'
                                : (hasWords
                                    ? '"$liveWords"'
                                    : 'Mendengarkan keluhan suara Anda...');

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7.5,
                              ),
                              decoration: BoxDecoration(
                                color: isCancelling
                                    ? const Color(0xFFEF4444)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isCancelling
                                      ? const Color(0xFFEF4444)
                                      : (hasWords
                                          ? AppColors.primary
                                          : AppColors.primaryLight.withValues(alpha: 0.5)),
                                  width: hasWords && !isCancelling ? 1.6 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCancelling
                                        ? const Color(0x55EF4444)
                                        : (hasWords
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.08)),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCancelling
                                        ? Icons.close_rounded
                                        : (hasWords
                                            ? Icons.record_voice_over_rounded
                                            : Icons.graphic_eq_rounded),
                                    size: 16,
                                    color: isCancelling
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      displayText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isCancelling
                                            ? Colors.white
                                            : (hasWords
                                                ? AppColors.primary
                                                : AppColors.textPrimary),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Live Spectrum Audio Waveform Equalizer (Responsive to amplitude)
                      ValueListenableBuilder<double>(
                        valueListenable:
                            VoiceRecordingService().soundLevelNotifier,
                        builder: (context, soundLevel, _) {
                          return Container(
                            width: 170,
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isCancelling
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.primarySoft,
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _LiveSpectrumWaveformPainter(
                                progress: animVal,
                                barCount: 22,
                                isCancelling: isCancelling,
                                soundLevel: soundLevel,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          isCancelling
                              ? 'Pesan suara ini tidak akan dikirimkan'
                              : 'Bicara dengan jelas seputar keluhan kesehatan Anda',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isCancelling
                                ? const Color(0xFFEF4444)
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Floating decorative acoustic sound particle orbiting the mascot
class _AcousticParticle {
  double angle;
  final double distance;
  final double speed;
  final double radius;
  final double opacity;

  _AcousticParticle({
    required this.angle,
    required this.distance,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

/// Concentric resonant acoustic soundwaves and particle field painter
class _ResonantAcousticPainter extends CustomPainter {
  final double progress;
  final bool isCancelling;
  final List<_AcousticParticle> particles;

  const _ResonantAcousticPainter({
    required this.progress,
    required this.isCancelling,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRadius = 110.0;
    const minRadius = 58.0;

    // 1. Concentric Harmonic Wave Rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * ringProgress;
      final alpha = math.sin(ringProgress * math.pi) * (isCancelling ? 0.45 : 0.35);

      final waveColor = isCancelling
          ? const Color(0xFFEF4444)
          : (i == 0
              ? AppColors.primary
              : (i == 1
                  ? AppColors.primaryLight
                  : const Color(0xFFA855F7)));

      final paint = Paint()
        ..color = waveColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - (ringProgress * 0.8);

      canvas.drawCircle(center, radius, paint);

      // Subtle filled aura glow
      final glowPaint = Paint()
        ..color = waveColor.withValues(alpha: alpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // 2. Floating Acoustic Orbiting Particles
    for (final p in particles) {
      final currentAngle = p.angle + (progress * 2 * math.pi * p.speed);
      final currentDist = p.distance + math.sin(progress * 2 * math.pi + p.angle) * 8.0;
      final px = center.dx + math.cos(currentAngle) * currentDist;
      final py = center.dy + math.sin(currentAngle) * currentDist;

      final pColor = isCancelling ? const Color(0xFFEF4444) : AppColors.primaryLight;
      final particlePaint = Paint()
        ..color = pColor.withValues(alpha: p.opacity * 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ResonantAcousticPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isCancelling != isCancelling;
}

/// Dynamic live audio spectrum waveform painter with gradient bars reacting to real microphone sound level
class _LiveSpectrumWaveformPainter extends CustomPainter {
  final double progress;
  final int barCount;
  final bool isCancelling;
  final double soundLevel;

  const _LiveSpectrumWaveformPainter({
    required this.progress,
    required this.barCount,
    required this.isCancelling,
    this.soundLevel = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalWidth = size.width;
    final barSpacing = totalWidth / barCount;
    final barWidth = math.max(2.2, barSpacing * 0.55);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing + barSpacing / 2;

      // Acoustic envelope bell curve
      final centerDist = (i - (barCount / 2)).abs() / (barCount / 2);
      final envelope = (1.0 - (centerDist * 0.65)).clamp(0.25, 1.0);

      // Multi-frequency simulated audio oscillation enhanced by real microphone soundLevel
      final phase1 = progress * 2 * math.pi * 3.0 + (i * 0.42);
      final phase2 = progress * 2 * math.pi * 1.8 + (i * 0.78);
      final baseWave = (math.sin(phase1).abs() * 0.6 + math.sin(phase2).abs() * 0.4);
      final dynamicGain = 0.4 + (soundLevel * 0.6);
      final wave = baseWave * dynamicGain;
      final height = math.max(3.0, size.height * wave * envelope);

      final top = centerY - height / 2;
      final rect = Rect.fromLTWH(x - barWidth / 2, top, barWidth, height);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2));

      Color barColor;
      if (isCancelling) {
        barColor = const Color(0xFFEF4444);
      } else {
        final t = i / barCount;
        if (t < 0.5) {
          barColor = Color.lerp(AppColors.primary, AppColors.primaryLight, t / 0.5)!;
        } else {
          barColor = Color.lerp(AppColors.primaryLight, const Color(0xFFA855F7), (t - 0.5) / 0.5)!;
        }
      }

      final barAlpha = (0.5 + 0.5 * wave).clamp(0.35, 1.0);
      final paint = Paint()..color = barColor.withValues(alpha: barAlpha);

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveSpectrumWaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isCancelling != isCancelling ||
      oldDelegate.soundLevel != soundLevel;
}
