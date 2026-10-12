import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/profile/presentation/controllers/personal_info_controller.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_conditions_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_contraception_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_reproductive_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_section_header.dart';

/// Step 3: Profil Kesehatan & Gaya Hidup.
class PersonalInfoStepHealth extends StatelessWidget {
  final PersonalInfoController controller;

  const PersonalInfoStepHealth({
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
          icon: Icons.health_and_safety_outlined,
          title: 'Profil Kesehatan & Gaya Hidup',
          subtitle: 'Kondisi ginekologis, kontrasepsi, dan riwayat kesehatan keluarga',
        ),
        const SizedBox(height: AppSizes.space16),

        // Status Reproduksi
        PersonalInfoReproductivePicker(
          selectedStatus: controller.reproductiveStatus,
          onStatusSelected: controller.updateReproductiveStatus,
        ),
        const SizedBox(height: AppSizes.space16),

        // Kontrasepsi
        PersonalInfoContraceptionPicker(
          selectedContraception: controller.contraception,
          onContraceptionSelected: controller.updateContraception,
        ),
        const SizedBox(height: AppSizes.space16),

        // Riwayat Medis & Keluarga
        PersonalInfoConditionsPicker(
          selectedConditions: controller.gynecologicalConditions,
          selectedFamilyHistory: controller.familyMedicalHistory,
          onConditionsChanged: controller.updateGynecologicalConditions,
          onFamilyHistoryChanged: controller.updateFamilyMedicalHistory,
        ),
        const SizedBox(height: AppSizes.space16),

        // Usia Menstruasi Pertama (Menarche)
        _buildMenarcheCard(),
        const SizedBox(height: AppSizes.space16),

        // Tingkat Aktivitas Fisik
        _buildActivityLevelCard(),
      ],
    );
  }

  Widget _buildMenarcheCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usia Menstruasi Pertama (Menarche)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Perkiraan usia ketika pertama kali mengalami haid.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(9, (index) {
                final age = 10 + index;
                final isSelected = controller.menarcheAge == age;
                return InkWell(
                  onTap: () => controller.updateMenarcheAge(age),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : const Color(0xFFF7F4F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE8DFE5),
                      ),
                    ),
                    child: Text(
                      '$age th',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () => controller.updateMenarcheAge(null),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.menarcheAge == null ? AppColors.primary : const Color(0xFFF7F4F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.menarcheAge == null ? AppColors.primary : const Color(0xFFE8DFE5),
                    ),
                  ),
                  child: Text(
                    'Tidak Ingat / Rahasiakan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: controller.menarcheAge == null ? FontWeight.w700 : FontWeight.w500,
                      color: controller.menarcheAge == null ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelCard() {
    const activityItems = [
      (id: 'sedentary', title: 'Banyak Duduk (Jarang Olahraga)'),
      (id: 'light', title: 'Ringan (Jalan Santai / Aktivitas Harian)'),
      (id: 'moderate', title: 'Sedang (Olahraga 2-3x Seminggu)'),
      (id: 'active', title: 'Aktif (Olahraga Rutin 4-5x Seminggu)'),
      (id: 'prefer_not_to_say', title: 'Dirahasiakan'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.space14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tingkat Aktivitas Fisik Harian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...activityItems.map((item) {
            final isSelected = controller.activityLevel == item.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => controller.updateActivityLevel(item.id),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0F5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFEDE5EC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 16,
                        color: isSelected ? AppColors.primary : const Color(0xFFC7BAC2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
