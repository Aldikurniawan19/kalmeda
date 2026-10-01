import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Interactive selector for reproductive status in Personal Info screen.
class PersonalInfoReproductivePicker extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  const PersonalInfoReproductivePicker({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  static const _options = [
    (
      id: 'single',
      title: 'Belum Menikah / Tidak Promil',
      icon: Icons.person_outline_rounded,
    ),
    (
      id: 'planning_pregnancy',
      title: 'Merencanakan Kehamilan (Promil)',
      icon: Icons.favorite_outline_rounded,
    ),
    (
      id: 'pregnant',
      title: 'Sedang Hamil',
      icon: Icons.pregnant_woman_rounded,
    ),
    (
      id: 'postpartum',
      title: 'Pasca Melahirkan / Menyusui',
      icon: Icons.child_care_rounded,
    ),
    (
      id: 'not_planning',
      title: 'Sudah Menikah (Belum Promil)',
      icon: Icons.people_outline_rounded,
    ),
    (
      id: 'prefer_not_to_say',
      title: 'Dirahasiakan (Tidak Ingin Menjawab)',
      icon: Icons.visibility_off_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Reproduksi Saat Ini',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        ..._options.map((item) {
          final isSelected = selectedStatus == item.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: InkWell(
              onTap: () => onStatusSelected(item.id),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.space12, vertical: AppSizes.space10),
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
                    Icon(
                      item.icon,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.space12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
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
