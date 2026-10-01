import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Interactive selector for contraception methods in Personal Info screen.
class PersonalInfoContraceptionPicker extends StatelessWidget {
  final String selectedContraception;
  final ValueChanged<String> onContraceptionSelected;

  const PersonalInfoContraceptionPicker({
    super.key,
    required this.selectedContraception,
    required this.onContraceptionSelected,
  });

  static const _options = [
    (id: 'none', title: 'Tidak Menggunakan Kontrasepsi'),
    (id: 'pill', title: 'Pil KB Hormonal'),
    (id: 'injection', title: 'Suntik KB (1/3 Bulan)'),
    (id: 'implant', title: 'Implan / Susuk KB'),
    (id: 'iud_hormonal', title: 'IUD Hormonal (Mirena/Kyleena)'),
    (id: 'iud_copper', title: 'IUD Tembaga (Non-Hormonal)'),
    (id: 'patch_ring', title: 'Patch / Cincin Vagina'),
    (id: 'prefer_not_to_say', title: 'Dirahasiakan (Tidak Ingin Menjawab)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Kontrasepsi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _options.any((o) => o.id == selectedContraception) ? selectedContraception : 'none',
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              items: _options.map((item) {
                return DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onContraceptionSelected(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
