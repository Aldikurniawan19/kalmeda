import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step configuration model for RecordStepperHeader
class RecordStepItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const RecordStepItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Interactive and modern top stepper header for RecordScreen.
/// Features a continuous connecting line track between all steps (no gaps),
/// and a smooth fluid flowing animation that only plays when moving between steps.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class RecordStepperHeader extends StatefulWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  static const List<RecordStepItem> steps = [
    RecordStepItem(
      title: 'Siklus & Mood',
      subtitle: 'Aliran & suasana hati',
      icon: Icons.water_drop_outlined,
    ),
    RecordStepItem(
      title: 'Gejala & Fisik',
      subtitle: 'Keluhan & gaya hidup',
      icon: Icons.healing_outlined,
    ),
    RecordStepItem(
      title: 'Catatan & Saran',
      subtitle: 'Analisis & kesimpulan',
      icon: Icons.assignment_outlined,
    ),
  ];

  const RecordStepperHeader({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  State<RecordStepperHeader> createState() => _RecordStepperHeaderState();
}

class _RecordStepperHeaderState extends State<RecordStepperHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late Animation<double> _stepAnimation;

  bool _isAdvancing = true;

  @override
  void initState() {
    super.initState();

    // Transition controller: only animates when moving between steps (no infinite loop)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stepAnimation = AlwaysStoppedAnimation<double>(
      widget.currentStep.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant RecordStepperHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentStep != widget.currentStep) {
      final from = _stepAnimation.value;
      final to = widget.currentStep.toDouble();

      _isAdvancing = to > from;

      _stepAnimation = Tween<double>(
        begin: from,
        end: to,
      ).animate(
        CurvedAnimation(
          parent: _transitionController,
          curve: Curves.easeInOutCubic,
        ),
      );

      _transitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: const Color(0xFFFFE6EE),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicators row with connected track & transition flow animation
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final stepCount = RecordStepperHeader.steps.length;
              const circleSize = 36.0;
              const topPadding = 4.0;
              const circleCenterY = topPadding + (circleSize / 2); // 22.0

              // Center X coordinate for each step node
              final stepCenters = List.generate(stepCount, (i) {
                return (i + 0.5) * (totalWidth / stepCount);
              });

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Connected Track behind circles (animates flow on step change)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _transitionAnimationListenable,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _StepperFlowTrackPainter(
                            stepCenters: stepCenters,
                            circleCenterY: circleCenterY,
                            circleRadius: circleSize / 2,
                            stepProgress: _stepAnimation.value,
                            isAnimating: _transitionController.isAnimating,
                            isAdvancing: _isAdvancing,
                            primaryColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Step Nodes (touch-friendly columns with circle & title)
                  Row(
                    children: [
                      for (int i = 0; i < stepCount; i++)
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onStepTapped(i),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: topPadding,
                                bottom: AppSizes.space4,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStepCircle(i, circleSize),
                                  const SizedBox(height: AppSizes.space8),
                                  Text(
                                    RecordStepperHeader.steps[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: i == widget.currentStep
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: i == widget.currentStep
                                          ? AppColors.primary
                                          : (i < widget.currentStep
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSizes.space10),

          // Progress subtitle informative banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space12,
              vertical: AppSizes.space6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.space6),
                Expanded(
                  child: Text(
                    'Langkah ${widget.currentStep + 1} dari ${RecordStepperHeader.steps.length}: ${RecordStepperHeader.steps[widget.currentStep].subtitle}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Listenable get _transitionAnimationListenable => _transitionController;

  Widget _buildStepCircle(int index, double size) {
    final bool isCurrent = index == widget.currentStep;
    final bool isCompleted = index < widget.currentStep;

    Color bgColor;
    Color iconColor;
    Border? border;

    if (isCurrent) {
      bgColor = AppColors.primary;
      iconColor = AppColors.textWhite;
    } else if (isCompleted) {
      bgColor = AppColors.primarySoft;
      iconColor = AppColors.primary;
    } else {
      bgColor = const Color(0xFFFBF8FA);
      iconColor = AppColors.textMuted;
      border = Border.all(color: const Color(0xFFE5DEE3), width: 1.5);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              )
            : Icon(
                RecordStepperHeader.steps[index].icon,
                size: 18,
                color: iconColor,
              ),
      ),
    );
  }
}

/// CustomPainter that renders:
/// 1. A continuous base connecting track linking all steps with zero disjointed gaps.
/// 2. An active filled liquid line that flows smoothly from previous step to target step when transitioning.
/// 3. A flowing fluid surge head with luminous droplet crest only while advancing to the next step.
class _StepperFlowTrackPainter extends CustomPainter {
  final List<double> stepCenters;
  final double circleCenterY;
  final double circleRadius;
  final double stepProgress;
  final bool isAnimating;
  final bool isAdvancing;
  final Color primaryColor;

  _StepperFlowTrackPainter({
    required this.stepCenters,
    required this.circleCenterY,
    required this.circleRadius,
    required this.stepProgress,
    required this.isAnimating,
    required this.isAdvancing,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stepCenters.length < 2) return;

    final startX = stepCenters.first;
    final endX = stepCenters.last;
    final y = circleCenterY;
    const trackWidth = 4.0;

    // 1. Base Inactive Track (Physical channel seamlessly connecting all step centers)
    final basePaint = Paint()
      ..color = const Color(0xFFEDE6EB)
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), basePaint);

    // 2. Active Filled Liquid Track (Flows forward/backward with stepProgress)
    final currentFillX = _getXForProgress(stepProgress);
    if (currentFillX > startX) {
      final activeGradient = LinearGradient(
        colors: [
          primaryColor,
          const Color(0xFFFF5E87),
        ],
      );
      final activePaint = Paint()
        ..shader = activeGradient.createShader(
          Rect.fromPoints(Offset(startX, y), Offset(currentFillX, y)),
        )
        ..strokeWidth = trackWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, y), Offset(currentFillX, y), activePaint);

      // 3. Fluid Surge Wave Head (Only active during forward transition to next step)
      if (isAnimating && isAdvancing) {
        // Glowing fluid droplet crest at the leading edge
        final headGlowPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.38)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(currentFillX, y), 4.2, headGlowPaint);

        final headCorePaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(currentFillX, y), 2.5, headCorePaint);

        final headWhitePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(currentFillX - 0.4, y - 0.4),
          1.2,
          headWhitePaint,
        );

        // Fluid highlight trail trailing behind the surge front (length ~20px)
        final trailStart = math.max(startX, currentFillX - 20.0);
        if (currentFillX > trailStart) {
          final trailShader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.75),
            ],
          ).createShader(
            Rect.fromLTRB(trailStart, y - 2, currentFillX, y + 2),
          );

          final trailPaint = Paint()
            ..shader = trailShader
            ..strokeWidth = trackWidth
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

          canvas.drawLine(
            Offset(trailStart, y),
            Offset(currentFillX, y),
            trailPaint,
          );
        }
      }
    }
  }

  double _getXForProgress(double progress) {
    if (progress <= 0) return stepCenters.first;
    if (progress >= stepCenters.length - 1) return stepCenters.last;
    final lower = progress.floor();
    final fraction = progress - lower;
    return stepCenters[lower] +
        (stepCenters[lower + 1] - stepCenters[lower]) * fraction;
  }

  @override
  bool shouldRepaint(covariant _StepperFlowTrackPainter oldDelegate) {
    return oldDelegate.stepProgress != stepProgress ||
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.isAdvancing != isAdvancing;
  }
}
