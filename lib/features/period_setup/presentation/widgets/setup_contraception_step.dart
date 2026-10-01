import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 7: Contraceptive Usage Information.
class SetupContraceptionStep extends StatelessWidget {
  final String selectedContraception;
  final ValueChanged<String> onContraceptionSelected;

  const SetupContraceptionStep({
    super.key,
    required this.selectedContraception,
    required this.onContraceptionSelected,
  });

  static const _contraceptionOptions = [
    {
      'id': 'none',
      'title': 'Tidak Menggunakan Kontrasepsi',
      'subtitle': 'Siklus hormonal berjalan murni secara alami.',
      'icon': Icons.block_rounded,
    },
    {
      'id': 'pill',
      'title': 'Pil KB Hormonal',
      'subtitle': 'Pil kombinasi atau minipil progestin harian.',
      'icon': Icons.medication_outlined,
    },
    {
      'id': 'injection',
      'title': 'Suntik KB (1 Bulan / 3 Bulan)',
      'subtitle': 'Injeksi hormon progestin atau kombinasi berkala.',
      'icon': Icons.vaccines_outlined,
    },
    {
      'id': 'implant',
      'title': 'Implan / Susuk KB',
      'subtitle': 'Batang silikon pelepas hormon di bawah kulit lengan.',
      'icon': Icons.healing_outlined,
    },
    {
      'id': 'iud_hormonal',
      'title': 'IUD Hormonal (Mirena / Kyleena)',
      'subtitle': 'Alat kontrasepsi dalam rahim dengan pelepasan hormon lokal.',
      'icon': Icons.health_and_safety_outlined,
    },
    {
      'id': 'iud_copper',
      'title': 'IUD Tembaga (Non-Hormonal)',
      'subtitle': 'Spiral tembaga yang tidak mengubah ritme ovulasi hormon alami.',
      'icon': Icons.shield_outlined,
    },
    {
      'id': 'patch_ring',
      'title': 'Patch / Cincin Vagina',
      'subtitle': 'Koyo hormon transdermal atau cincin elastis berkala.',
      'icon': Icons.adjust_rounded,
    },
    {
      'id': 'prefer_not_to_say',
      'title': 'Tidak Ingin Menjawab',
      'subtitle': 'Informasi ini dirahasiakan dan tidak akan dicatat.',
      'icon': Icons.visibility_off_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penggunaan Kontrasepsi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Metode kontrasepsi hormonal dapat mempengaruhi ritme ovulasi alami, volume darah haid, dan siklus bulanan Anda.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space16),

        // Clinical notice box
        Container(
          padding: const EdgeInsets.all(AppSizes.space12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5F8),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFEADBDF)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSizes.space8),
              Expanded(
                child: Text(
                  'Bila Anda menggunakan kontrasepsi hormonal (seperti pil, implan, atau suntik), tubuh mungkin tidak mengalami ovulasi alami dan perdarahan yang muncul adalah withdrawal bleeding.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.space20),

        ..._contraceptionOptions.map((item) {
          final isSelected = selectedContraception == item['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space10),
            child: InkWell(
              onTap: () => onContraceptionSelected(item['id'] as String),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSizes.space12),
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
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFFFF4F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.primary : const Color(0xFFD6C8CF),
                      size: 20,
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
