import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Multi-select chip editor for personal gynecological conditions and family medical history in Personal Info screen.
class PersonalInfoConditionsPicker extends StatelessWidget {
  final List<String> selectedConditions;
  final List<String> selectedFamilyHistory;
  final ValueChanged<List<String>> onConditionsChanged;
  final ValueChanged<List<String>> onFamilyHistoryChanged;

  const PersonalInfoConditionsPicker({
    super.key,
    required this.selectedConditions,
    required this.selectedFamilyHistory,
    required this.onConditionsChanged,
    required this.onFamilyHistoryChanged,
  });

  static const _personalOptions = [
    (id: 'pcos', title: 'PCOS'),
    (id: 'endometriosis', title: 'Endometriosis'),
    (id: 'myoma_cyst', title: 'Miom / Kista'),
    (id: 'anemia', title: 'Anemia Defisiensi Besi'),
    (id: 'thyroid', title: 'Gangguan Tiroid'),
    (id: 'none', title: 'Tidak Ada Riwayat'),
    (id: 'prefer_not_to_say', title: 'Dirahasiakan'),
  ];

  static const _familyOptions = [
    (id: 'pcos', title: 'PCOS Turunan'),
    (id: 'endometriosis', title: 'Endometriosis'),
    (id: 'myoma', title: 'Miom Rahim'),
    (id: 'breast_cervical_cancer', title: 'Kanker Payudara/Serviks'),
    (id: 'none', title: 'Tidak Ada / Tidak Tahu'),
    (id: 'prefer_not_to_say', title: 'Dirahasiakan'),
  ];

  void _togglePersonal(String id) {
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

  void _toggleFamily(String id) {
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
        // Personal Conditions
        const Text(
          'Riwayat Kondisi Ginekologis Pribadi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _personalOptions.map((item) {
            final isSelected = selectedConditions.contains(item.id);
            return InkWell(
              onTap: () => _togglePersonal(item.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.inputBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSizes.space16),

        // Family Medical History
        const Text(
          'Riwayat Kesehatan Keluarga Dekat (Ibu/Saudari)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _familyOptions.map((item) {
            final isSelected = selectedFamilyHistory.contains(item.id);
            return InkWell(
              onTap: () => _toggleFamily(item.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.inputBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
