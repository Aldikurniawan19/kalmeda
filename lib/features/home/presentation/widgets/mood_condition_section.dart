import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Dynamic Mood & Condition section with interactive mood shortcuts and clinical guidance.
class MoodConditionSection extends StatelessWidget {
  final ValueChanged<int>? onMoodSelected;

  const MoodConditionSection({
    super.key,
    this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final dayInfo = controller.cycleOverview?.currentDayInfo;
        final record = controller.selectedDateRecord;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mood & Kondisi Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dayInfo != null ? 'Hari ke-${dayInfo.cycleDay}' : '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space14),

            // Mood horizontal selector list
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  _MoodCard(
                    label: 'Bahagia',
                    iconPath: 'assets/icon/iconBahagia.png',
                    bgColor: AppColors.moodBahagiaBg,
                    isSelected: record?.moodIndex == 0,
                    onTap: () => onMoodSelected?.call(0),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  _MoodCard(
                    label: 'Tenang',
                    iconPath: 'assets/icon/iconTenang.png',
                    bgColor: AppColors.moodTenangBg,
                    isSelected: record?.moodIndex == 1,
                    onTap: () => onMoodSelected?.call(1),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  _MoodCard(
                    label: 'Sedih',
                    iconPath: 'assets/icon/iconSedih.png',
                    bgColor: AppColors.moodSedihBg,
                    isSelected: record?.moodIndex == 2,
                    onTap: () => onMoodSelected?.call(2),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  _MoodCard(
                    label: 'Lelah',
                    iconPath: 'assets/icon/iconLelah.png',
                    bgColor: AppColors.moodLelahBg,
                    isSelected: record?.moodIndex == 3,
                    onTap: () => onMoodSelected?.call(3),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  _MoodCard(
                    label: 'Nyeri',
                    iconPath: 'assets/icon/iconNyeri.png',
                    bgColor: AppColors.moodNyeriBg,
                    isSelected: record?.moodIndex == 4,
                    onTap: () => onMoodSelected?.call(4),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  _MoodCard(
                    label: 'Kembung',
                    iconPath: 'assets/icon/iconKembung.png',
                    bgColor: AppColors.moodKembungBg,
                    isSelected: record?.moodIndex == 5,
                    onTap: () => onMoodSelected?.call(5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space16),

            // Clinical Daily Health Guidance Card
            if (dayInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.space16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: const Color(0xFFFFE3EC), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D79).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.space6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.spa_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kondisi Tubuh: ${dayInfo.phaseName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                dayInfo.pregnancyProbabilityText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space10),
                    Text(
                      dayInfo.clinicalGuidance,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSizes.space10),
                    const Divider(height: 1, color: Color(0xFFF7F3F8)),
                    const SizedBox(height: AppSizes.space10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.restaurant_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSizes.space6),
                        Expanded(
                          child: Text(
                            'Saran Nutrisi: ${dayInfo.nutritionTip}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.label,
    required this.iconPath,
    required this.bgColor,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 60,
        height: 78,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2.0) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSizes.space6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
