import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/profile/presentation/controllers/personal_info_controller.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_date_picker_tile.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_goal_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_regularity_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_section_header.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_stepper_slider.dart';

/// Step 2: Parameter Siklus Menstruasi.
class PersonalInfoStepCycle extends StatelessWidget {
  final PersonalInfoController controller;

  const PersonalInfoStepCycle({
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
          icon: Icons.water_drop_outlined,
          title: 'Parameter Siklus Haid',
          subtitle: 'Pengaturan utama untuk menghitung prediksi haid dan masa subur',
        ),
        const SizedBox(height: AppSizes.space16),

        // Tujuan Pelacakan
        PersonalInfoGoalPicker(
          selectedGoal: controller.trackingGoal,
          onGoalSelected: controller.updateTrackingGoal,
        ),
        const SizedBox(height: AppSizes.space16),

        // Tanggal Haid Terakhir
        PersonalInfoDatePickerTile(
          label: 'Hari Pertama Haid Terakhir',
          selectedDate: controller.lastPeriodDate,
          firstDate: DateTime(2020, 1, 1),
          lastDate: DateTime.now(),
          onDateSelected: controller.updateLastPeriodDate,
          helperText: 'Titik acuan awal untuk kalkulasi kalender siklus berikutnya.',
        ),
        const SizedBox(height: AppSizes.space16),

        // Rata-rata Panjang Siklus
        PersonalInfoStepperSlider(
          label: 'Panjang Siklus Rata-rata',
          value: controller.cycleLength,
          min: 21,
          max: 45,
          unit: 'hari',
          clinicalNote: 'Rentang siklus normal medis adalah 21 – 35 hari.',
          onChanged: controller.updateCycleLength,
        ),
        const SizedBox(height: AppSizes.space16),

        // Durasi Menstruasi
        PersonalInfoStepperSlider(
          label: 'Durasi Rata-rata Menstruasi',
          value: controller.periodDuration,
          min: 2,
          max: 10,
          unit: 'hari',
          clinicalNote: 'Rentang lama pendarahan normal medis adalah 3 – 7 hari.',
          onChanged: controller.updatePeriodDuration,
        ),
        const SizedBox(height: AppSizes.space16),

        // Keteraturan Siklus
        PersonalInfoRegularityPicker(
          selectedRegularity: controller.regularity,
          onRegularitySelected: controller.updateRegularity,
        ),
      ],
    );
  }
}
