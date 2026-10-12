import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Clean, informative empty state displayed when no menstrual records exist within the 6-month window.
class PeriodHistoryEmptyState extends StatelessWidget {
  final VoidCallback? onAddRecord;

  const PeriodHistoryEmptyState({super.key, this.onAddRecord});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.space20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D79).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/Komponen/komponenKalender.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSizes.space20),

          const Text(
            'Belum Ada Riwayat Haid Tersimpan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSizes.space8),

          const Text(
            'Data menstruasi Anda belum tercatat di penyimpanan. Mulai catat hari pertama haid dan kondisi fisik Anda untuk melihat riwayat siklus secara akurat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSizes.space24),

          // Primary Call to Action Button
          ElevatedButton.icon(
            onPressed: onAddRecord,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Catat Menstruasi Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space24,
                vertical: AppSizes.space12,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space24),

          // Clinical Importance Tip
          Container(
            padding: const EdgeInsets.all(AppSizes.space12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: const Color(0xFFF0ECF3), width: 1.0),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: Color(0xFF8E24AA),
                ),
                SizedBox(width: AppSizes.space8),
                Expanded(
                  child: Text(
                    'Catatan minimal 2–3 siklus berurutan sangat penting untuk memprediksi masa subur, ovulasi, serta mengenali pola keteraturan hormon reproduksi Anda.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
