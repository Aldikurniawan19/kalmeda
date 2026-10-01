import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Lifestyle metrics (Hydration, Sleep, Exercise) section.
class LifestyleSelectorSection extends StatelessWidget {
  final int waterCups;
  final ValueChanged<int> onWaterChanged;
  final int exerciseIndex;
  final ValueChanged<int> onExerciseSelected;

  const LifestyleSelectorSection({
    super.key,
    required this.waterCups,
    required this.onWaterChanged,
    required this.exerciseIndex,
    required this.onExerciseSelected,
  });

  static const _exerciseLevels = ['Tidak Ada', 'Ringan', 'Sedang', 'Intensif'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas & Hidrasi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // Water Tracker Card
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFF4EFF5), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_drink_rounded,
                      size: 22,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konsumsi Air Putih',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$waterCups Gelas (${waterCups * 250} ml)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _CounterButton(
                    icon: Icons.remove,
                    onTap: waterCups > 0 ? () => onWaterChanged(waterCups - 1) : null,
                  ),
                  const SizedBox(width: AppSizes.space8),
                  Text(
                    '$waterCups',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space8),
                  _CounterButton(
                    icon: Icons.add,
                    onTap: () => onWaterChanged(waterCups + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // Exercise Level Selector
        Container(
          padding: const EdgeInsets.all(AppSizes.space14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFF4EFF5), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.directions_run_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSizes.space6),
                  Text(
                    'Aktivitas Fisik / Olahraga',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_exerciseLevels.length, (index) {
                  final isSelected = exerciseIndex == index;

                  return InkWell(
                    onTap: () => onExerciseSelected(index),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space10,
                        vertical: AppSizes.space6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF0F4) : const Color(0xFFFAF7F9),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _exerciseLevels[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFFFF0F4) : const Color(0xFFF7F4F7),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
