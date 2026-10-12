import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/cycle_history_bottom_sheet.dart';

/// Card showing dynamic donut chart and progress bars calculated from real user logs.
class MoodConditionChartCard extends StatelessWidget {
  const MoodConditionChartCard({super.key});

  static const _moodConfig = [
    {
      'label': 'Bahagia',
      'icon': 'assets/icon/iconBahagia.png',
      'color': Color(0xFFFFB800),
    },
    {
      'label': 'Tenang',
      'icon': 'assets/icon/iconTenang.png',
      'color': Color(0xFF26C6DA),
    },
    {
      'label': 'Sedih',
      'icon': 'assets/icon/iconSedih.png',
      'color': Color(0xFF42A5F5),
    },
    {
      'label': 'Lelah',
      'icon': 'assets/icon/iconLelah.png',
      'color': Color(0xFFB57AFF),
    },
    {
      'label': 'Nyeri',
      'icon': 'assets/icon/iconNyeri.png',
      'color': Color(0xFFFF5280),
    },
    {
      'label': 'Kembung',
      'icon': 'assets/icon/iconKembung.png',
      'color': Color(0xFFFB923C),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final records = HomeController().monthRecords;
        final totalCount = records.length;

        // Calculate real distribution counts
        final counts = List<int>.filled(6, 0);
        for (final r in records) {
          final idx = r.moodIndex.clamp(0, 5);
          counts[idx]++;
        }

        // Calculate real percentage ratios
        final percentages = List<double>.generate(6, (i) {
          if (totalCount == 0) return 0.0;
          return counts[i] / totalCount;
        });

        return Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mood & Kondisi ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        totalCount > 0
                            ? '($totalCount Catatan)'
                            : '(Bulan Ini)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => CycleHistoryBottomSheet.show(context),
                    child: Row(
                      children: const [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSizes.space2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space16),

              if (totalCount == 0)
                // Empty state if no records yet
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.space12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: AppColors.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum Ada Catatan Mood',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Catat suasana hatimu di menu Catat untuk melihat grafik distribusi emosi real-time.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Dynamic Donut Chart + Breakdown list
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Dynamic Donut Chart
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(105, 105),
                            painter: _DynamicMoodDonutChartPainter(
                              percentages: percentages,
                            ),
                          ),
                          // Center pink smiley face
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5280),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sentiment_satisfied_alt_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.space16),

                    // Right: Real Mood progress bars
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          final cfg = _moodConfig[index];
                          final ratio = percentages[index];
                          final pctString = '${(ratio * 100).round()}%';

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < 4 ? AppSizes.space8 : 0,
                            ),
                            child: _MoodProgressItem(
                              iconPath: cfg['icon'] as String,
                              label: cfg['label'] as String,
                              percentage: pctString,
                              progress: ratio,
                              barColor: cfg['color'] as Color,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MoodProgressItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final String percentage;
  final double progress;
  final Color barColor;

  const _MoodProgressItem({
    required this.iconPath,
    required this.label,
    required this.percentage,
    required this.progress,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(iconPath, width: 16, height: 16, fit: BoxFit.contain),
        const SizedBox(width: AppSizes.space6),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : 0.02,
              backgroundColor: const Color(0xFFF3EFF5),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0 ? barColor : const Color(0xFFE5DEE6),
              ),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.space8),
        SizedBox(
          width: 32,
          child: Text(
            percentage,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicMoodDonutChartPainter extends CustomPainter {
  final List<double> percentages;

  const _DynamicMoodDonutChartPainter({required this.percentages});

  static const _colors = [
    Color(0xFFFFB800), // Bahagia (Yellow)
    Color(0xFF26C6DA), // Tenang (Mint / Cyan)
    Color(0xFF42A5F5), // Sedih (Blue)
    Color(0xFFB57AFF), // Lelah (Purple)
    Color(0xFFFF5280), // Nyeri (Pink)
    Color(0xFFFB923C), // Kembung (Orange)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final total = percentages.fold<double>(0.0, (prev, p) => prev + p);
    if (total == 0) {
      final basePaint = Paint()
        ..color = const Color(0xFFF3EFF5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius - strokeWidth / 2, basePaint);
      return;
    }

    double currentAngle = -math.pi / 2;

    for (int i = 0; i < percentages.length; i++) {
      final pct = percentages[i];
      if (pct <= 0.001) continue;

      final sweepAngle = 2 * math.pi * pct;
      final paint = Paint()
        ..color = _colors[i % _colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, currentAngle, sweepAngle - 0.04, false, paint);
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicMoodDonutChartPainter oldDelegate) {
    return oldDelegate.percentages != percentages;
  }
}
