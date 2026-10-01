import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 5: Cycle Regularity & Flexible Birth Date (Day, Month, Year) with live age calculation.
class SetupRegularityStep extends StatelessWidget {
  final String selectedRegularity;
  final DateTime birthDate;
  final ValueChanged<String> onRegularitySelected;
  final ValueChanged<DateTime> onBirthDateChanged;

  const SetupRegularityStep({
    super.key,
    required this.selectedRegularity,
    required this.birthDate,
    required this.onRegularitySelected,
    required this.onBirthDateChanged,
  });

  static const _regularityOptions = [
    {
      'id': 'regular',
      'title': 'Sangat Teratur',
      'subtitle': 'Jadwal menstruasi hampir selalu tepat waktu (variasi kurang dari 3 hari).',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'id': 'sometimes_variable',
      'title': 'Kadang Bergeser',
      'subtitle': 'Jadwal terkadang maju atau mundur beberapa hari (variasi 3–7 hari).',
      'icon': Icons.change_circle_outlined,
    },
    {
      'id': 'irregular',
      'title': 'Tidak Teratur / Sering Berubah',
      'subtitle': 'Jadwal sering tidak menentu atau siklus sering melompat.',
      'icon': Icons.shuffle_rounded,
    },
  ];

  String _formatIndonesianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Calculates exact age in years and months based on the current date.
  Map<String, int> _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    return {'years': years, 'months': months};
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final today = DateTime.now();
    final initial = birthDate.isAfter(today) ? DateTime(2000, 1, 1) : birthDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(today.year - 10, today.month, today.day),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onBirthDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ageMap = _calculateAge(birthDate);
    final ageYears = ageMap['years'] ?? 0;
    final ageMonths = ageMap['months'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bagaimana keteraturan siklus dan tanggal lahirmu?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Informasi ini menyempurnakan algoritma prediksi siklus agar sesuai dengan kestabilan hormon dan fase usiamu.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space20),

        // 1. Regularity options
        const Text(
          'Keteraturan Siklus',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        ..._regularityOptions.map((item) {
          final isSelected = selectedRegularity == item['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space10),
            child: InkWell(
              onTap: () => onRegularitySelected(item['id'] as String),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space16,
                  vertical: AppSizes.space12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0F5) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFFFE2EA),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSizes.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
        const SizedBox(height: AppSizes.space16),

        // 2. Flexible Date of Birth (Tanggal, Bulan, Tahun)
        const Text(
          'Tanggal Lahir',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        InkWell(
          onTap: () => _selectBirthDate(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space16,
              vertical: AppSizes.space14,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: const Color(0xFFFFDDE6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D79).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Tanggal, Bulan, & Tahun Lahir',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatIndonesianDate(birthDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_calendar_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        // 3. Live Age Calculation Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F9),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFFFE0EA), width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usia kamu saat ini:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      ageMonths > 0
                          ? '$ageYears tahun $ageMonths bulan'
                          : '$ageYears tahun',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                  vertical: AppSizes.space4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD1DE)),
                ),
                child: Text(
                  ageYears < 20
                      ? 'Fase Remaja'
                      : (ageYears < 40 ? 'Reproduksi Aktif' : 'Fase Dewasa'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
