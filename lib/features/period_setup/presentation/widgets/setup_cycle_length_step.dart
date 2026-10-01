import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 3: Average Cycle Length Selection (ACOG standard: 21–35 days, typical 28).
class SetupCycleLengthStep extends StatelessWidget {
  final int cycleLength;
  final ValueChanged<int> onCycleLengthChanged;

  const SetupCycleLengthStep({
    super.key,
    required this.cycleLength,
    required this.onCycleLengthChanged,
  });

  static const _quickOptions = [24, 26, 28, 30, 32, 35];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Berapa hari rata-rata panjang siklusmu?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Panjang siklus dihitung dari hari ke-1 menstruasi sampai 1 hari sebelum menstruasi berikutnya dimulai. Standar medis normal adalah 21–35 hari (rata-rata 28 hari).',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space32),

        // Center Interactive Counter Card
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.space24,
              horizontal: AppSizes.space20,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(color: const Color(0xFFFFDDE6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D79).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Panjang Siklus',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Minus Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: cycleLength > 21
                            ? () => onCycleLengthChanged(cycleLength - 1)
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cycleLength > 21
                                ? const Color(0xFFFFF0F5)
                                : const Color(0xFFF6F6F6),
                            border: Border.all(
                              color: cycleLength > 21
                                  ? const Color(0xFFFFD1DE)
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: cycleLength > 21
                                ? AppColors.primary
                                : const Color(0xFFBDBDBD),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.space28),

                    // Number Display
                    Column(
                      children: [
                        Text(
                          '$cycleLength',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hari',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.space28),

                    // Plus Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: cycleLength < 45
                            ? () => onCycleLengthChanged(cycleLength + 1)
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cycleLength < 45
                                ? const Color(0xFFFFF0F5)
                                : const Color(0xFFF6F6F6),
                            border: Border.all(
                              color: cycleLength < 45
                                  ? const Color(0xFFFFD1DE)
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: cycleLength < 45
                                ? AppColors.primary
                                : const Color(0xFFBDBDBD),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.space16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space12,
                    vertical: AppSizes.space6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F8),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    cycleLength == 28
                        ? 'Standar umum medis sebagian besar wanita'
                        : 'Rentang normal (21–35 hari)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space20),

        // Quick Selector Chips
        const Text(
          'Pilihan cepat:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickOptions.map((days) {
            final isSelected = cycleLength == days;
            return ChoiceChip(
              label: Text('$days hari'),
              selected: isSelected,
              onSelected: (_) => onCycleLengthChanged(days),
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFFFF6F8),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFFFD8E2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
