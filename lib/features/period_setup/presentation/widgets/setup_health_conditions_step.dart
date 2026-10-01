import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 8: Personal Gynecological History and Family Medical History with Strict Privacy Guarantees.
class SetupHealthConditionsStep extends StatelessWidget {
  final List<String> selectedConditions;
  final List<String> selectedFamilyHistory;
  final ValueChanged<List<String>> onConditionsChanged;
  final ValueChanged<List<String>> onFamilyHistoryChanged;

  const SetupHealthConditionsStep({
    super.key,
    required this.selectedConditions,
    required this.selectedFamilyHistory,
    required this.onConditionsChanged,
    required this.onFamilyHistoryChanged,
  });

  static const _personalConditions = [
    {
      'id': 'pcos',
      'title': 'PCOS (Sindrom Ovarium Polikistik)',
      'subtitle': 'Ketidakseimbangan hormon yang sering membuat siklus tidak teratur.',
    },
    {
      'id': 'endometriosis',
      'title': 'Endometriosis',
      'subtitle': 'Pertumbuhan jaringan di luar rahim yang memicu nyeri hebat saat haid.',
    },
    {
      'id': 'myoma_cyst',
      'title': 'Miom / Kista Ovarium',
      'subtitle': 'Pertumbuhan non-kanker pada otot rahim atau kantung cairan ovarium.',
    },
    {
      'id': 'anemia',
      'title': 'Anemia Defisiensi Besi',
      'subtitle': 'Kekurangan sel darah merah yang memperparah rasa lelah saat haid.',
    },
    {
      'id': 'thyroid',
      'title': 'Gangguan Hormon Tiroid',
      'subtitle': 'Hipotiroid atau hipertiroid yang mempengaruhi keteraturan siklus.',
    },
    {
      'id': 'none',
      'title': 'Tidak Ada Riwayat / Belum Pernah Didiagnosis',
      'subtitle': 'Kondisi ginekologis dinyatakan sehat tanpa diagnosis spesifik.',
    },
    {
      'id': 'prefer_not_to_say',
      'title': 'Tidak Ingin Menjawab',
      'subtitle': 'Rahasiakan data riwayat kondisi kesehatan pribadi.',
    },
  ];

  static const _familyConditions = [
    {
      'id': 'pcos',
      'title': 'PCOS / Gangguan Keteraturan Siklus',
      'subtitle': 'Riwayat siklus tidak menentu pada ibu atau saudari kandung.',
    },
    {
      'id': 'endometriosis',
      'title': 'Endometriosis / Nyeri Haid Hebat Turunan',
      'subtitle': 'Riwayat nyeri panggul signifikan pada keluarga dekat.',
    },
    {
      'id': 'myoma',
      'title': 'Miom / Tumor Jinak Rahim',
      'subtitle': 'Riwayat pembedahan miom atau perdarahan hebat.',
    },
    {
      'id': 'breast_cervical_cancer',
      'title': 'Kanker Payudara / Serviks',
      'subtitle': 'Penting untuk penyesuaian rekomendasi skrining pencegahan rutin.',
    },
    {
      'id': 'none',
      'title': 'Tidak Ada / Tidak Tahu',
      'subtitle': 'Tidak ada catatan riwayat penyakit khusus pada keluarga.',
    },
    {
      'id': 'prefer_not_to_say',
      'title': 'Tidak Ingin Menjawab',
      'subtitle': 'Rahasiakan riwayat kesehatan keluarga.',
    },
  ];

  void _toggleCondition(String id) {
    final updated = List<String>.from(selectedConditions);
    if (id == 'none' || id == 'prefer_not_to_say') {
      updated.clear();
      updated.add(id);
    } else {
      updated.remove('none');
      updated.remove('prefer_not_to_say');
      if (updated.contains(id)) {
        updated.remove(id);
        if (updated.isEmpty) updated.add('none');
      } else {
        updated.add(id);
      }
    }
    onConditionsChanged(updated);
  }

  void _toggleFamilyCondition(String id) {
    final updated = List<String>.from(selectedFamilyHistory);
    if (id == 'none' || id == 'prefer_not_to_say') {
      updated.clear();
      updated.add(id);
    } else {
      updated.remove('none');
      updated.remove('prefer_not_to_say');
      if (updated.contains(id)) {
        updated.remove(id);
        if (updated.isEmpty) updated.add('none');
      } else {
        updated.add(id);
      }
    }
    onFamilyHistoryChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Kesehatan & Keluarga',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Data klinis membantu Kalmeda memberikan saran pencegahan komplikasi, pemantauan gejala yang tepat, dan analisis medis berbasis bukti.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space16),

        // Privacy Guarantee Banner
        Container(
          padding: const EdgeInsets.all(AppSizes.space14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFD6E2F0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: Color(0xFF2C6ECB),
              ),
              SizedBox(width: AppSizes.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privasi & Kerahasiaan Medis Terjamin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E529E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Seluruh data kesehatan disimpan secara aman dan terenkripsi. Data ini murni digunakan untuk menyesuaikan rekomendasi klinis pribadi Anda.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A688F),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.space20),

        // Section 1: Personal Gynecological History
        const Text(
          'Riwayat Kondisi Ginekologis Pribadi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bisa pilih lebih dari satu jika relevan.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        ..._personalConditions.map((item) {
          final isSelected = selectedConditions.contains(item['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: InkWell(
              onTap: () => _toggleCondition(item['id'] as String),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F5) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFFFE2EA),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? AppColors.primary : const Color(0xFFC7BAC2),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: AppSizes.space20),

        // Section 2: Family Medical History
        const Text(
          'Riwayat Kesehatan Keluarga Dekat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Riwayat pada ibu atau saudari kandung (bisa pilih lebih dari satu).',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        ..._familyConditions.map((item) {
          final isSelected = selectedFamilyHistory.contains(item['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: InkWell(
              onTap: () => _toggleFamilyCondition(item['id'] as String),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F5) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFFFE2EA),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? AppColors.primary : const Color(0xFFC7BAC2),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
