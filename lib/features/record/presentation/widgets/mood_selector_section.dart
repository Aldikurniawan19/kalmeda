import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Interactive mood selection section with asset icons.
class MoodSelectorSection extends StatelessWidget {
  final int selectedMoodIndex;
  final ValueChanged<int> onMoodSelected;

  const MoodSelectorSection({
    super.key,
    required this.selectedMoodIndex,
    required this.onMoodSelected,
  });

  static const _moods = [
    {
      'label': 'Bahagia',
      'iconPath': 'assets/icon/iconBahagia.png',
      'bgColor': AppColors.moodBahagiaBg,
    },
    {
      'label': 'Tenang',
      'iconPath': 'assets/icon/iconTenang.png',
      'bgColor': AppColors.moodTenangBg,
    },
    {
      'label': 'Sedih',
      'iconPath': 'assets/icon/iconSedih.png',
      'bgColor': AppColors.moodSedihBg,
    },
    {
      'label': 'Lelah',
      'iconPath': 'assets/icon/iconLelah.png',
      'bgColor': AppColors.moodLelahBg,
    },
    {
      'label': 'Sensitif',
      'iconPath': 'assets/icon/iconMood.png',
      'bgColor': AppColors.moodNyeriBg,
    },
    {
      'label': 'Kembung',
      'iconPath': 'assets/icon/iconKembung.png',
      'bgColor': AppColors.moodKembungBg,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood & Perasaan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space4),
        const Text(
          'Bagaimana suasana hatimu hari ini?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // Horizontal Mood List
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: List.generate(_moods.length, (index) {
              final isSelected = selectedMoodIndex == index;
              final mood = _moods[index];

              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.space10),
                child: InkWell(
                  onTap: () => onMoodSelected(index),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 64,
                    height: 80,
                    decoration: BoxDecoration(
                      color: mood['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(18),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2.0)
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFFFF4D79).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          mood['iconPath'] as String,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSizes.space6),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
