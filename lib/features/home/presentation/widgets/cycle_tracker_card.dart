import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Dynamic Cycle Tracker Card showing countdown, cycle day progress ring, and phase badge.
class CycleTrackerCard extends StatelessWidget {
  final VoidCallback? onRecordTap;

  const CycleTrackerCard({super.key, this.onRecordTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final homeController = HomeController();
        final overview = homeController.cycleOverview;

        final currentCycleDay = overview?.currentCycleDay ?? 1;
        final totalCycleLength = overview?.cycleLength ?? 28;
        final progressFraction =
            overview?.progressFraction ?? (currentCycleDay / totalCycleLength);
        final countdownTitle = overview?.countdownTitle ?? 'Menghitung...';
        final countdownSubtitle =
            overview?.countdownSubtitle ?? 'siklus menstruasi';
        final nextPeriodText = overview != null
            ? 'Perkiraan: ${DateFormatter.format(overview.nextPeriodDate)}'
            : 'Perkiraan: -';
        final phaseName =
            overview?.currentDayInfo.phaseName ?? 'Fase Menstruasi';

        // Dynamic accessible badge colors to ensure readable text contrast on all phases
        final isOvulation = overview?.currentPhase == CyclePhase.ovulation;
        final isFertile = overview?.currentPhase == CyclePhase.fertileWindow;
        final badgeColor = isOvulation
            ? AppColors.ovulationSolid
            : isFertile
            ? AppColors.fertileWindowText
            : AppColors.primary;
        final badgeBg = isOvulation
            ? AppColors.ovulationSoft
            : isFertile
            ? AppColors.fertileWindowBg
            : const Color(0xFFFFEDF2);
        final badgeBorder = isOvulation
            ? const Color(0xFFDDD6FE)
            : isFertile
            ? AppColors.fertileWindowBorder
            : const Color(0xFFFFD4E2);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFFFE8EF), width: 1.2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF4F7), Color(0xFFFFFFFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D79).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Information & CTA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Phase Badge with high contrast colors
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.space10,
                              vertical: AppSizes.space4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSmall,
                              ),
                              border: Border.all(
                                color: badgeBorder,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.space6),
                                Text(
                                  phaseName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.space8),

                          // Dynamic Countdown Title with comfortable proportions
                          Text(
                            countdownTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSizes.space4),

                          // Subtitle with clear line height
                          Text(
                            countdownSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSizes.space6),

                          // Next Predicted Period with calendar icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSizes.space4),
                              Flexible(
                                child: Text(
                                  nextPeriodText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.space12),

                          // Pill Button: Catat Menstruasi
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onRecordTap ?? () {},
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusCircular,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.space12,
                                  vertical: AppSizes.space8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5280),
                                      Color(0xFFFF6F93),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusCircular,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF4D79,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Catat Menstruasi',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.space6),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppColors.textWhite,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.space12),

                    // Right Column: Dynamic Progress Ring
                    SizedBox(
                      width: 114,
                      height: 114,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Circular Progress Painter
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _CycleProgressPainter(
                              progress: progressFraction,
                              trackColor: const Color(0xFFFFE8F0),
                              progressColor: const Color(0xFFFF5280),
                            ),
                          ),

                          // Center text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$currentCycleDay',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Hari ke',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'dari $totalCycleLength hari',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          // Flower decoration layered on the ring
                          Positioned(
                            bottom: -10,
                            right: -6,
                            child: Image.asset(
                              'assets/Komponen/komponenBunga.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the cycle circular progress bar with gradient and indicator cap
class _CycleProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  const _CycleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 14) / 2;
    const strokeWidth = 10.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFFFFA3BA), Color(0xFFFF4876)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = (2 * math.pi * progress).clamp(0.01, 2 * math.pi);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // End indicator dot (white circle with pink stroke)
    final endAngle = startAngle + sweepAngle;
    final endX = center.dx + radius * math.cos(endAngle);
    final endY = center.dy + radius * math.sin(endAngle);
    final dotCenter = Offset(endX, endY);

    final dotOuterPaint = Paint()
      ..color = const Color(0xFFFF5280)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 5.5, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 3.2, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _CycleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
