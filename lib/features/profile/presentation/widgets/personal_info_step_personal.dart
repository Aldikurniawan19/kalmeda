import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/profile/presentation/controllers/personal_info_controller.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_date_picker_tile.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_section_header.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_text_field.dart';

/// Step 1: Identitas & Data Diri.
class PersonalInfoStepPersonal extends StatelessWidget {
  final PersonalInfoController controller;

  const PersonalInfoStepPersonal({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const PersonalInfoSectionHeader(
          icon: Icons.person_outline_rounded,
          title: 'Data Diri & Akun',
          subtitle: 'Perbarui nama lengkap, email, dan tanggal lahir Anda',
        ),
        const SizedBox(height: AppSizes.space16),

        // Nama Lengkap
        PersonalInfoTextField(
          label: 'Nama Lengkap',
          controller: controller.nameController,
          prefixIcon: Icons.badge_outlined,
          hintText: 'Masukkan nama lengkap',
        ),
        const SizedBox(height: AppSizes.space16),

        // Email (Read-only)
        PersonalInfoTextField(
          label: 'Email Akun',
          initialValue: controller.email,
          prefixIcon: Icons.mail_outline_rounded,
          readOnly: true,
        ),
        const SizedBox(height: AppSizes.space16),

        // Tanggal Lahir
        PersonalInfoDatePickerTile(
          label: 'Tanggal Lahir',
          selectedDate: controller.birthDate,
          firstDate: DateTime(1950, 1, 1),
          lastDate: DateTime.now(),
          onDateSelected: controller.updateBirthDate,
          helperText: 'Digunakan untuk akurasi rekomendasi kesehatan dan usia reproduksi.',
        ),
        const SizedBox(height: AppSizes.space20),

        // Privacy note card
        Container(
          padding: const EdgeInsets.all(AppSizes.space14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7FA),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFEDE6EE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSizes.space10),
              Expanded(
                child: Text(
                  'Data pribadi Anda tersimpan secara privat, aman, dan hanya digunakan untuk personalisasi pelacakan siklus Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
