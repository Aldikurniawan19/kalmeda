import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Flow intensity selection section with interactive cards.
class FlowSelectorSection extends StatelessWidget {
  final int selectedFlowIndex;
  final ValueChanged<int> onFlowSelected;
  final bool isPeriod;

  const FlowSelectorSection({
    super.key,
    required this.selectedFlowIndex,
    required this.onFlowSelected,
    this.isPeriod = true,
  });

  static const _flowOptions = [
    {'title': 'Tidak Ada', 'subtitle': 'Bersih'},
    {'title': 'Flek', 'subtitle': 'Bercak ringan'},
    {'title': 'Ringan', 'subtitle': 'Aliran sedikit'},
    {'title': 'Sedang', 'subtitle': 'Aliran normal'},
    {'title': 'Deras', 'subtitle': 'Aliran banyak'},
  ];

  @override
  Widget build(BuildContext context) {
    // When not in menstrual period, strictly only show the "Tidak Ada / Bersih" option
    final displayedOptions = isPeriod ? _flowOptions : [_flowOptions.first];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aliran Menstruasi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space4),
        const Text(
          'Pilih intensitas aliran darah hari ini',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // Horizontal options list
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: List.generate(displayedOptions.length, (index) {
              final isSelected = selectedFlowIndex == index;
              final opt = displayedOptions[index];

              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.space10),
                child: InkWell(
                  onTap: () => onFlowSelected(index),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: Container(
                    width: 82,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.space12,
                      horizontal: AppSizes.space6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF0F4)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF4EFF5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFFFF4D79).withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(AppSizes.space6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFDEE7)
                                : const Color(0xFFFAF6F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: index == 0
                              ? Icon(
                                  Icons.do_not_disturb_on_outlined,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                )
                              : Image.asset(
                                  'assets/icon/darahIsght.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(height: AppSizes.space8),
                        Text(
                          opt['title']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.space2),
                        Text(
                          opt['subtitle']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
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
