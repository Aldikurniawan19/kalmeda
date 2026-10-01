import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/profile/presentation/controllers/personal_info_controller.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_conditions_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_contraception_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_date_picker_tile.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_goal_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_regularity_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_reproductive_picker.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_section_header.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_stepper_slider.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_text_field.dart';

/// Screen allowing the user to view and update personal data and menstrual cycle parameters.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final PersonalInfoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersonalInfoController();
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await _controller.saveChanges();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi pribadi dan siklus berhasil diperbarui.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Informasi Pribadi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: const Color(0xFFF3EFF4),
                height: 1,
              ),
            ),
          ),
          body: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space20,
                      vertical: AppSizes.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Banner if present
                        if (_controller.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSizes.space12),
                            margin: const EdgeInsets.only(bottom: AppSizes.space16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.space10),
                                Expanded(
                                  child: Text(
                                    _controller.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Section 1: Data Diri
                        const PersonalInfoSectionHeader(
                          icon: Icons.person_outline_rounded,
                          title: 'Data Diri',
                          subtitle: 'Informasi identitas dan tanggal lahir Anda',
                        ),
                        const SizedBox(height: AppSizes.space12),

                        // Nama Lengkap
                        PersonalInfoTextField(
                          label: 'Nama Lengkap',
                          controller: _controller.nameController,
                          prefixIcon: Icons.badge_outlined,
                          hintText: 'Masukkan nama lengkap',
                        ),
                        const SizedBox(height: AppSizes.space14),

                        // Email (Read-only)
                        PersonalInfoTextField(
                          label: 'Email Akun',
                          initialValue: _controller.email,
                          prefixIcon: Icons.mail_outline_rounded,
                          readOnly: true,
                        ),
                        const SizedBox(height: AppSizes.space14),

                        // Tanggal Lahir
                        PersonalInfoDatePickerTile(
                          label: 'Tanggal Lahir',
                          selectedDate: _controller.birthDate,
                          firstDate: DateTime(1950, 1, 1),
                          lastDate: DateTime.now(),
                          onDateSelected: _controller.updateBirthDate,
                          helperText: 'Digunakan untuk akurasi rekomendasi kesehatan siklus.',
                        ),
                        const SizedBox(height: AppSizes.space24),

                        // Divider
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1ECF3),
                        ),
                        const SizedBox(height: AppSizes.space20),

                        // Section 2: Pengaturan Siklus Menstruasi
                        const PersonalInfoSectionHeader(
                          icon: Icons.water_drop_outlined,
                          title: 'Pengaturan Siklus Menstruasi',
                          subtitle: 'Parameter utama untuk menghitung prediksi haid dan masa subur',
                        ),
                        const SizedBox(height: AppSizes.space14),

                        // Tujuan Pelacakan
                        PersonalInfoGoalPicker(
                          selectedGoal: _controller.trackingGoal,
                          onGoalSelected: _controller.updateTrackingGoal,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Tanggal Haid Terakhir
                        PersonalInfoDatePickerTile(
                          label: 'Hari Pertama Haid Terakhir',
                          selectedDate: _controller.lastPeriodDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 120)),
                          lastDate: DateTime.now(),
                          onDateSelected: _controller.updateLastPeriodDate,
                          helperText: 'Titik acuan awal untuk kalkulasi kalender siklus berikutnya.',
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Rata-rata Panjang Siklus
                        PersonalInfoStepperSlider(
                          label: 'Panjang Siklus Rata-rata',
                          value: _controller.cycleLength,
                          min: 21,
                          max: 45,
                          unit: 'hari',
                          clinicalNote: 'Rentang siklus normal medis adalah 21 – 35 hari.',
                          onChanged: _controller.updateCycleLength,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Durasi Menstruasi
                        PersonalInfoStepperSlider(
                          label: 'Durasi Rata-rata Menstruasi',
                          value: _controller.periodDuration,
                          min: 2,
                          max: 10,
                          unit: 'hari',
                          clinicalNote: 'Rentang lama pendarahan normal medis adalah 3 – 7 hari.',
                          onChanged: _controller.updatePeriodDuration,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Keteraturan Siklus
                        PersonalInfoRegularityPicker(
                          selectedRegularity: _controller.regularity,
                          onRegularitySelected: _controller.updateRegularity,
                        ),
                        const SizedBox(height: AppSizes.space24),

                        // Divider
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1ECF3),
                        ),
                        const SizedBox(height: AppSizes.space20),

                        // Section 3: Profil Kesehatan & Gaya Hidup
                        const PersonalInfoSectionHeader(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Profil Kesehatan & Gaya Hidup',
                          subtitle: 'Kondisi ginekologis, kontrasepsi, dan riwayat kesehatan keluarga',
                        ),
                        const SizedBox(height: AppSizes.space14),

                        // Status Reproduksi
                        PersonalInfoReproductivePicker(
                          selectedStatus: _controller.reproductiveStatus,
                          onStatusSelected: _controller.updateReproductiveStatus,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Kontrasepsi
                        PersonalInfoContraceptionPicker(
                          selectedContraception: _controller.contraception,
                          onContraceptionSelected: _controller.updateContraception,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Riwayat Medis & Keluarga
                        PersonalInfoConditionsPicker(
                          selectedConditions: _controller.gynecologicalConditions,
                          selectedFamilyHistory: _controller.familyMedicalHistory,
                          onConditionsChanged: _controller.updateGynecologicalConditions,
                          onFamilyHistoryChanged: _controller.updateFamilyMedicalHistory,
                        ),
                        const SizedBox(height: AppSizes.space16),

                        // Usia Menstruasi Pertama (Menarche)
                        Container(
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
                                    final isSelected = _controller.menarcheAge == age;
                                    return InkWell(
                                      onTap: () => _controller.updateMenarcheAge(age),
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
                                    onTap: () => _controller.updateMenarcheAge(null),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _controller.menarcheAge == null ? AppColors.primary : const Color(0xFFF7F4F7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _controller.menarcheAge == null ? AppColors.primary : const Color(0xFFE8DFE5),
                                        ),
                                      ),
                                      child: Text(
                                        'Tidak Ingat / Rahasiakan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _controller.menarcheAge == null ? FontWeight.w700 : FontWeight.w500,
                                          color: _controller.menarcheAge == null ? Colors.white : AppColors.textPrimary,
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

                        // Tingkat Aktivitas Fisik
                        Container(
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
                              ...[
                                (id: 'sedentary', title: 'Banyak Duduk (Jarang Olahraga)'),
                                (id: 'light', title: 'Ringan (Jalan Santai / Aktivitas Harian)'),
                                (id: 'moderate', title: 'Sedang (Olahraga 2-3x Seminggu)'),
                                (id: 'active', title: 'Aktif (Olahraga Rutin 4-5x Seminggu)'),
                                (id: 'prefer_not_to_say', title: 'Dirahasiakan'),
                              ].map((item) {
                                final isSelected = _controller.activityLevel == item.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () => _controller.updateActivityLevel(item.id),
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
                        ),
                        const SizedBox(height: AppSizes.space28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _controller.isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFFFB3C7),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              ),
                            ),
                            child: _controller.isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.space20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
