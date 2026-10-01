import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 6: Reproductive Status, Menarche Age, and Daily Physical Activity Level.
class SetupReproductiveStatusStep extends StatelessWidget {
  final String selectedStatus;
  final int? selectedMenarcheAge;
  final String selectedActivityLevel;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<int?> onMenarcheAgeChanged;
  final ValueChanged<String> onActivityLevelChanged;

  const SetupReproductiveStatusStep({
    super.key,
    required this.selectedStatus,
    required this.selectedMenarcheAge,
    required this.selectedActivityLevel,
    required this.onStatusSelected,
    required this.onMenarcheAgeChanged,
    required this.onActivityLevelChanged,
  });

  static const _statusOptions = [
    {
      'id': 'single',
      'title': 'Belum Menikah / Tidak Promil',
      'subtitle': 'Fokus memantau keteraturan siklus dan gejala bulanan.',
      'icon': Icons.person_outline_rounded,
    },
    {
      'id': 'planning_pregnancy',
      'title': 'Merencanakan Kehamilan (Promil)',
      'subtitle': 'Menonjolkan estimasi masa subur, ovulasi, dan jendela konsepsi.',
      'icon': Icons.favorite_outline_rounded,
    },
    {
      'id': 'pregnant',
      'title': 'Sedang Hamil',
      'subtitle': 'Menyesuaikan mode pelacakan khusus usia kehamilan.',
      'icon': Icons.pregnant_woman_rounded,
    },
    {
      'id': 'postpartum',
      'title': 'Pasca Melahirkan / Menyusui',
      'subtitle': 'Pendampingan fase nifas dan pemulihan siklus hormon.',
      'icon': Icons.child_care_rounded,
    },
    {
      'id': 'not_planning',
      'title': 'Sudah Menikah (Belum Promil)',
      'subtitle': 'Manajemen siklus alami dan pencegahan kehamilan terencana.',
      'icon': Icons.people_outline_rounded,
    },
    {
      'id': 'prefer_not_to_say',
      'title': 'Tidak Ingin Menjawab',
      'subtitle': 'Informasi ini dirahasiakan dan tidak akan mempengaruhi fitur dasar.',
      'icon': Icons.visibility_off_outlined,
    },
  ];

  static const _activityOptions = [
    {
      'id': 'sedentary',
      'title': 'Banyak Duduk',
      'subtitle': 'Bekerja di meja / jarang berolahraga',
    },
    {
      'id': 'light',
      'title': 'Ringan',
      'subtitle': 'Jalan kaki santai / pekerjaan rumah tangga',
    },
    {
      'id': 'moderate',
      'title': 'Sedang',
      'subtitle': 'Olahraga 2-3 kali dalam seminggu',
    },
    {
      'id': 'active',
      'title': 'Aktif / Intensif',
      'subtitle': 'Olahraga teratur 4-5 kali seminggu',
    },
    {
      'id': 'prefer_not_to_say',
      'title': 'Lewati',
      'subtitle': 'Tidak ingin mengisi tingkat aktivitas',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Reproduksi & Gaya Hidup',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Informasi ini membantu Kalmeda menyajikan artikel, perkiraan fase hormonal, dan tips kebugaran yang relevan dengan kebutuhanmu.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space20),

        // Section 1: Reproductive Status
        const Text(
          'Status reproduksi saat ini',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        ..._statusOptions.map((item) {
          final isSelected = selectedStatus == item['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space10),
            child: InkWell(
              onTap: () => onStatusSelected(item['id'] as String),
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

        const SizedBox(height: AppSizes.space20),

        // Section 2: Menarche Age (First Period)
        Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFFFE2EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.space8),
                  const Expanded(
                    child: Text(
                      'Usia Menstruasi Pertama (Menarche)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Perkiraan usia ketika pertama kali mengalami haid.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.space12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(9, (index) {
                    final age = 10 + index; // 10 to 18
                    final isSelected = selectedMenarcheAge == age;
                    return InkWell(
                      onTap: () => onMenarcheAgeChanged(age),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFFFF4F7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFFFD5E0),
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
                    onTap: () => onMenarcheAgeChanged(null),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedMenarcheAge == null ? AppColors.primary : const Color(0xFFFFF4F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedMenarcheAge == null ? AppColors.primary : const Color(0xFFFFD5E0),
                        ),
                      ),
                      child: Text(
                        'Tidak Ingat / Lewati',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedMenarcheAge == null ? FontWeight.w700 : FontWeight.w500,
                          color: selectedMenarcheAge == null ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.space16),

        // Section 3: Physical Activity Level
        Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFFFE2EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.space8),
                  const Expanded(
                    child: Text(
                      'Tingkat Aktivitas Fisik Sehari-hari',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Membantu menyelaraskan rekomendasi energi dan istirahat tiap fase.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.space12),
              ..._activityOptions.map((item) {
                final isSelected = selectedActivityLevel == item['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => onActivityLevelChanged(item['id'] as String),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF0F5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFF0E5EC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 16,
                            color: isSelected ? AppColors.primary : const Color(0xFFC7BAC2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  item['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
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
        ),
      ],
    );
  }
}
