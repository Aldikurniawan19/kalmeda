import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Card displaying cycle phase analysis, clinical distribution, and normal medical ranges.
class CycleHistoryChartCard extends StatelessWidget {
  const CycleHistoryChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final overview = controller.cycleOverview;

        final cycleLength = overview?.cycleLength ?? 28;
        final periodDuration = overview?.periodDuration ?? 5;
        final ovulationDay = (cycleLength - 14).clamp(1, cycleLength - 1);
        final fertileStartDay = (ovulationDay - 5).clamp(1, ovulationDay);

        final follicularStartDay = periodDuration + 1;
        final follicularEndDay = fertileStartDay - 1;
        final follicularDays = (follicularEndDay >= follicularStartDay)
            ? (follicularEndDay - follicularStartDay + 1)
            : 0;
        final fertileDays = (ovulationDay - fertileStartDay + 1).clamp(1, 6);
        final lutealDays = (cycleLength - ovulationDay).clamp(1, cycleLength);

        final isNormalLength = cycleLength >= 21 && cycleLength <= 35;

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
              // Header Row with flexible wrapping to avoid clipping on small devices
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Analisis Siklus & Hormonal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space8,
                      vertical: AppSizes.space4,
                    ),
                    decoration: BoxDecoration(
                      color: isNormalLength ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: isNormalLength ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isNormalLength ? 'Rentang Medis Normal' : 'Perlu Pemantauan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isNormalLength ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space12),

              // Overview statement
              Text(
                'Siklus Anda diperkirakan $cycleLength hari dengan lama menstruasi $periodDuration hari.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.space14),

              // Segmented Visual Phase Bar with adaptive labels
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      // Menstrual phase
                      Expanded(
                        flex: periodDuration,
                        child: _BarSegment(
                          color: AppColors.primary,
                          label: 'Haid',
                          textColor: Colors.white,
                        ),
                      ),
                      // Follicular phase (only if days > 0)
                      if (follicularDays > 0) ...[
                        const SizedBox(width: 1),
                        Expanded(
                          flex: follicularDays,
                          child: _BarSegment(
                            color: const Color(0xFFFFB8CC),
                            label: 'Folikuler',
                            textColor: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 1),
                      // Fertile & Ovulation phase
                      Expanded(
                        flex: fertileDays,
                        child: _BarSegment(
                          color: AppColors.ovulationSolid,
                          label: 'Subur',
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 1),
                      // Luteal phase
                      Expanded(
                        flex: lutealDays,
                        child: _BarSegment(
                          color: const Color(0xFFFFD6E3),
                          label: 'Luteal',
                          textColor: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space16),

              // Phase breakdown details
              _PhaseDetailRow(
                dotColor: AppColors.primary,
                phaseTitle: 'Fase Menstruasi (Hari 1–$periodDuration)',
                description: 'Pelepasan lapisan dinding rahim dan darah haid.',
              ),
              const SizedBox(height: AppSizes.space8),
              _PhaseDetailRow(
                dotColor: const Color(0xFFFFB8CC),
                phaseTitle: follicularDays > 0
                    ? 'Fase Folikuler (Hari $follicularStartDay–$follicularEndDay)'
                    : 'Fase Folikuler (Transisi Cepat)',
                description: follicularDays > 0
                    ? 'Pematangan sel telur baru dan peningkatan energi.'
                    : 'Fase folikuler sangat singkat karena menstruasi berlangsung panjang.',
              ),
              const SizedBox(height: AppSizes.space8),
              _PhaseDetailRow(
                dotColor: AppColors.ovulationSolid,
                phaseTitle: 'Masa Subur & Ovulasi (Hari $fertileStartDay–$ovulationDay)',
                description: 'Puncak fertilitas dan pelepasan sel telur pada hari ke-$ovulationDay.',
              ),
              const SizedBox(height: AppSizes.space8),
              _PhaseDetailRow(
                dotColor: const Color(0xFFFFD6E3),
                phaseTitle: 'Fase Luteal & PMS (Hari ${ovulationDay + 1}–$cycleLength)',
                description: 'Dominasi progesteron dan persiapan siklus berikutnya.',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Segment in the visual phase bar that displays label only when width is comfortably large
class _BarSegment extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _BarSegment({
    required this.color,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Only show full label if width is sufficient (>= 48px), otherwise keep as clean colored segment
          if (width < 48) {
            return const SizedBox.shrink();
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhaseDetailRow extends StatelessWidget {
  final Color dotColor;
  final String phaseTitle;
  final String description;

  const _PhaseDetailRow({
    required this.dotColor,
    required this.phaseTitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phaseTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
