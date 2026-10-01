import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Interactive selector for menstrual tracking goal with rich option cards.
class PersonalInfoGoalPicker extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onGoalSelected;

  const PersonalInfoGoalPicker({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  static const _goals = [
    (
      id: 'predict_period',
      title: 'Prediksi Menstruasi',
      description: 'Mengetahui perkiraan siklus dan tanggal haid mendatang',
      icon: Icons.calendar_month_rounded,
    ),
    (
      id: 'fertility_ovulation',
      title: 'Kesuburan & Ovulasi',
      description: 'Mengetahui masa subur, jendela kesuburan, dan masa ovulasi',
      icon: Icons.favorite_rounded,
    ),
    (
      id: 'symptom_health',
      title: 'Pantau Gejala & Kesehatan',
      description: 'Mencatat perubahan mood, nyeri, dan gejala tubuh harian',
      icon: Icons.health_and_safety_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tujuan Pelacakan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        ..._goals.map((goal) {
          final isSelected = selectedGoal == goal.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: InkWell(
              onTap: () => onGoalSelected(goal.id),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.space12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F5) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.inputBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.space8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF7F4F7),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      child: Icon(
                        goal.icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.space8),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
