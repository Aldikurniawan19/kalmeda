import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Physical symptoms selector section with multi-select support.
class SymptomSelectorSection extends StatelessWidget {
  final Set<int> selectedSymptoms;
  final ValueChanged<int> onToggleSymptom;

  const SymptomSelectorSection({
    super.key,
    required this.selectedSymptoms,
    required this.onToggleSymptom,
  });

  static const _symptoms = [
    {'name': 'Kram Perut', 'icon': 'assets/icon/iconNyeri.png', 'isAsset': true},
    {'name': 'Kembung', 'icon': 'assets/icon/iconKembung.png', 'isAsset': true},
    {'name': 'Kelelahan', 'icon': 'assets/icon/iconLelah.png', 'isAsset': true},
    {'name': 'Sakit Kepala', 'icon': Icons.healing_rounded, 'isAsset': false},
    {'name': 'Sakit Pinggang', 'icon': Icons.accessibility_rounded, 'isAsset': false},
    {'name': 'Payudara Nyeri', 'icon': Icons.favorite_border_rounded, 'isAsset': false},
    {'name': 'Jerawat', 'icon': Icons.face_rounded, 'isAsset': false},
    {'name': 'Nafsu Makan', 'icon': Icons.restaurant_rounded, 'isAsset': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gejala Fisik & Keluhan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space4),
        const Text(
          'Pilih semua gejala yang kamu rasakan (bisa lebih dari satu)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // Grid of Wrap Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_symptoms.length, (index) {
            final isSelected = selectedSymptoms.contains(index);
            final symptom = _symptoms[index];
            final isAsset = symptom['isAsset'] as bool;

            return InkWell(
              onTap: () => onToggleSymptom(index),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space12,
                  vertical: AppSizes.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F4) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFF2EDF4),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFFFF4D79).withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAsset)
                      Image.asset(
                        symptom['icon'] as String,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      )
                    else
                      Icon(
                        symptom['icon'] as IconData,
                        size: 18,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    const SizedBox(width: AppSizes.space6),
                    Text(
                      symptom['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
