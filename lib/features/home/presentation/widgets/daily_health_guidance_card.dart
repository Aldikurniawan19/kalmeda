import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Card displaying personalized daily clinical recommendations for nutrition, physical activities, and relaxation,
/// automatically adapting based on whether menstruation has started, is in progress, or is overdue.
class DailyHealthGuidanceCard extends StatelessWidget {
  const DailyHealthGuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final overview = controller.cycleOverview;
        final dayInfo = overview?.currentDayInfo;

        if (overview == null || dayInfo == null) {
          return const SizedBox.shrink();
        }

        // Determine dynamic chip label & color based on menstruation status
        String chipText;
        Color chipBgColor;
        Color chipTextColor;
        Color chipBorderColor;

        final isOverdue = overview.daysUntilNextPeriod < 0 && !overview.isPeriodActive;

        if (overview.isPeriodActive) {
          chipText = 'Haid Hari ke-${overview.currentCycleDay}';
          chipBgColor = const Color(0xFFFFF0F5);
          chipTextColor = AppColors.primary;
          chipBorderColor = const Color(0xFFFFD4E2);
        } else if (overview.isPeriodProlonged) {
          chipText = 'Haid +${overview.prolongedDays} hari';
          chipBgColor = const Color(0xFFFFF3E0);
          chipTextColor = const Color(0xFFE65100);
          chipBorderColor = const Color(0xFFFFCC80);
        } else if (isOverdue) {
          final lateDays = -overview.daysUntilNextPeriod;
          chipText = 'Terlambat $lateDays hari';
          chipBgColor = const Color(0xFFFFF3E0);
          chipTextColor = const Color(0xFFE65100);
          chipBorderColor = const Color(0xFFFFCC80);
        } else if (overview.daysUntilNextPeriod == 0) {
          chipText = 'Hari H Perkiraan';
          chipBgColor = const Color(0xFFFFF0F5);
          chipTextColor = AppColors.primary;
          chipBorderColor = const Color(0xFFFFD4E2);
        } else if (overview.daysUntilNextPeriod == 1) {
          chipText = 'H-1 Menjelang Haid';
          chipBgColor = const Color(0xFFFFF0F5);
          chipTextColor = AppColors.primary;
          chipBorderColor = const Color(0xFFFFD4E2);
        } else if (overview.daysUntilNextPeriod == 2) {
          chipText = 'H-2 Menjelang Haid';
          chipBgColor = const Color(0xFFFFF0F5);
          chipTextColor = AppColors.primary;
          chipBorderColor = const Color(0xFFFFD4E2);
        } else {
          chipText = 'Hari ke-${overview.currentCycleDay}';
          chipBgColor = const Color(0xFFFFF0F5);
          chipTextColor = AppColors.primary;
          chipBorderColor = const Color(0xFFFFD4E2);
        }

        // Custom clinical texts if overdue (belum haid lewat dari tanggal perkiraan)
        final displayPhaseName = isOverdue
            ? 'Menjelang Haid (Terlambat ${-overview.daysUntilNextPeriod} Hari)'
            : dayInfo.phaseName;

        final displayPregnancyText = isOverdue
            ? 'Peluang Kehamilan Sangat Rendah'
            : dayInfo.pregnancyProbabilityText;

        final displayClinicalGuidance = isOverdue
            ? 'Menstruasi belum dimulai melewati tanggal perkiraan (${-overview.daysUntilNextPeriod} hari). Keterlambatan dapat dipengaruhi oleh fluktuasi hormon estrogen-progesteron, stres, kelelahan, atau pola tidur. Tetap rileks dan pantau kondisi tubuh.'
            : dayInfo.clinicalGuidance;

        final displayNutritionTip = isOverdue
            ? 'Konsumsi makanan kaya magnesium dan vitamin B6 (pisang, bayam, oat) serta perbanyak minum air hangat. Kurangi konsumsi kafein berlebih.'
            : dayInfo.nutritionTip;

        final displayPhysicalTip = isOverdue
            ? 'Lakukan peregangan panggul ringan, yoga relaksasi, atau kompres hangat di perut bagian bawah untuk membantu melancarkan sirkulasi.'
            : dayInfo.physicalTip;

        final displayMoodTip = isOverdue
            ? 'Prioritaskan tidur cukup dan kelola stres dengan baik. Hindari cemas berlebih karena hormon stres (kortisol) dapat menunda haid lebih lanjut.'
            : dayInfo.moodTip;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header: Title & Dynamic Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSizes.space8),
                    Text(
                      'Rekomendasi Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space10,
                    vertical: AppSizes.space4,
                  ),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(
                      AppSizes.radiusCircular,
                    ),
                    border: Border.all(
                      color: chipBorderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: chipTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space12),

            // Main Guidance Card
            Container(
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFFFE0EC), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF9FB), Color(0xFFFFFFFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D79).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase & Clinical Summary Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.space8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kondisi Tubuh: $displayPhaseName',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayPregnancyText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? const Color(0xFFE65100)
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space10),

                  // Clinical Guidance Text
                  Text(
                    displayClinicalGuidance,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space14),
                  const Divider(height: 1, color: Color(0xFFF6EEF4)),
                  const SizedBox(height: AppSizes.space12),

                  // Tip 1: Nutrition Recommendation Box
                  _GuidanceItem(
                    icon: Icons.restaurant_rounded,
                    title: 'Rekomendasi Makanan & Nutrisi',
                    content: displayNutritionTip,
                    iconBgColor: const Color(0xFFFFE8D6),
                    iconColor: const Color(0xFFE65100),
                    cardBgColor: const Color(0xFFFFF9F5),
                    borderColor: const Color(0xFFFFE5D0),
                  ),
                  const SizedBox(height: AppSizes.space10),

                  // Tip 2: Physical Activity Recommendation Box
                  _GuidanceItem(
                    icon: Icons.directions_walk_rounded,
                    title: 'Rekomendasi Aktivitas & Olahraga',
                    content: displayPhysicalTip,
                    iconBgColor: const Color(0xFFE0F2F1),
                    iconColor: const Color(0xFF00796B),
                    cardBgColor: const Color(0xFFF5FAF9),
                    borderColor: const Color(0xFFD6EDE9),
                  ),
                  const SizedBox(height: AppSizes.space10),

                  // Tip 3: Mental Health & Rest Recommendation Box
                  _GuidanceItem(
                    icon: Icons.self_improvement_rounded,
                    title: 'Saran Istirahat & Relaksasi',
                    content: displayMoodTip,
                    iconBgColor: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    cardBgColor: const Color(0xFFFAF5FC),
                    borderColor: const Color(0xFFEEDDF5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuidanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color iconBgColor;
  final Color iconColor;
  final Color cardBgColor;
  final Color borderColor;

  const _GuidanceItem({
    required this.icon,
    required this.title,
    required this.content,
    required this.iconBgColor,
    required this.iconColor,
    required this.cardBgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space12,
        vertical: AppSizes.space10,
      ),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.space6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: AppSizes.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
