import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Step 2: Last Menstrual Period (LMP) Date Selection.
class SetupDateStep extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const SetupDateStep({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _formatIndonesianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstAllowedDate = today.subtract(const Duration(days: 90));

    final safeInitialDate = selectedDate.isAfter(today)
        ? today
        : (selectedDate.isBefore(firstAllowedDate) ? firstAllowedDate : selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapan hari pertama menstruasi terakhirmu?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        const Text(
          'Pilih tanggal saat darah menstruasi pertama kali keluar (bukan flek ringan).',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSizes.space20),

        // Selected Date Highlight Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFFFD1DE), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSizes.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Terpilih',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatIndonesianDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space16),

        // Embedded Modern Date Picker Calendar
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFFFE6EE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D79).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: safeInitialDate,
              firstDate: firstAllowedDate,
              lastDate: today,
              onDateChanged: onDateSelected,
            ),
          ),
        ),
      ],
    );
  }
}
