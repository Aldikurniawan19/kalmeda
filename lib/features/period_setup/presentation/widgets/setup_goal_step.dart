import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 1: User Primary Tracking Goal Selection.
class SetupGoalStep extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onGoalSelected;

  const SetupGoalStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  static const _goals = [
    {
      'id': 'predict_period',
      'title': 'Memprediksi Jadwal Menstruasi',
      'subtitle': 'Ketahui perkiraan tanggal datang bulan berikutnya dengan akurat.',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'id': 'fertility_ovulation',
      'title': 'Memantau Masa Subur & Ovulasi',
      'subtitle': 'Dapatkan informasi jendela kesuburan untuk perencanaan keluarga.',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'id': 'symptom_health',
      'title': 'Memantau Pola Gejala & Kesehatan',
      'subtitle': 'Catat perubahan mood, fisik, dan tren hormonal tubuh setiap fase.',
      'icon': Icons.insights_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apa tujuan utama kamu menggunakan Kalmeda?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Pilihan ini membantu menyesuaikan tampilan ramalan dan notifikasi harian untukmu.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        ..._goals.map((item) {
          final isSelected = selectedGoal == item['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space12),
            child: InkWell(
              onTap: () => onGoalSelected(item['id'] as String),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSizes.space16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F5) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFFFE2EA),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFFFF4F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSizes.space14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.space4),
                          Text(
                            item['subtitle'] as String,
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
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFD4C2CB),
                          width: 2,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
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
