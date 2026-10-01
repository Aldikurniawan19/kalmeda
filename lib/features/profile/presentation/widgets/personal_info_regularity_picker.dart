import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Cycle regularity option selector with clinical guidance descriptions.
class PersonalInfoRegularityPicker extends StatelessWidget {
  final String selectedRegularity;
  final ValueChanged<String> onRegularitySelected;

  const PersonalInfoRegularityPicker({
    super.key,
    required this.selectedRegularity,
    required this.onRegularitySelected,
  });

  static const _options = [
    (
      id: 'regular',
      title: 'Teratur',
      description: 'Siklus selalu tepat waktu atau hanya berbeda 1–2 hari',
    ),
    (
      id: 'sometimes_variable',
      title: 'Kadang Bervariasi',
      description: 'Kadang maju atau mundur 3–6 hari dari perkiraan',
    ),
    (
      id: 'irregular',
      title: 'Tidak Teratur',
      description: 'Sering tidak teratur, jeda panjang, atau sulit ditebak',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keteraturan Siklus',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        ..._options.map((option) {
          final isSelected = selectedRegularity == option.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: InkWell(
              onTap: () => onRegularitySelected(option.id),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space14,
                  vertical: AppSizes.space12,
                ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
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
