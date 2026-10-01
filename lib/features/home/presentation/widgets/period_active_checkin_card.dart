import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Interactive card for active menstrual check-in, period completion, and prolonged bleeding clinical guidance.
class PeriodActiveCheckinCard extends StatelessWidget {
  final VoidCallback? onRecordTap;

  const PeriodActiveCheckinCard({
    super.key,
    this.onRecordTap,
  });

  Future<void> _handleConfirmEnded(BuildContext context, HomeController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Selesai Haid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Apakah darah menstruasi sudah benar-benar bersih hari ini? Sistem akan mencatat durasi aktual menstruasi untuk memperbarui prediksi siklus mendatang.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Sudah Bersih'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.confirmPeriodEnded(DateTime.now());
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status menstruasi diperbarui: Selesai. Durasi siklus telah disesuaikan.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Gagal memperbarui status menstruasi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final overview = controller.cycleOverview;

        if (overview == null || !overview.isPeriodActive || controller.hasCheckinToday) {
          return const SizedBox.shrink();
        }

        final isProlonged = overview.isPeriodProlonged;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.space16),
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: isProlonged ? const Color(0xFFFFF7ED) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(
              color: isProlonged ? const Color(0xFFFFCC80) : const Color(0xFFFFDDE6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isProlonged
                    ? Colors.orange.withValues(alpha: 0.08)
                    : const Color(0xFFFF4D79).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.space8),
                    decoration: BoxDecoration(
                      color: isProlonged ? const Color(0xFFFFE0B2) : const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isProlonged ? Icons.warning_amber_rounded : Icons.water_drop_rounded,
                      color: isProlonged ? const Color(0xFFE65100) : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProlonged
                              ? 'Menstruasi Melebihi Perkiraan (${overview.currentCycleDay} Hari)'
                              : 'Check-in Harian Menstruasi (Hari ke-${overview.currentCycleDay})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isProlonged ? const Color(0xFFE65100) : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isProlonged
                              ? 'Durasi darah haid berlangsung ${overview.prolongedDays} hari lebih lama dari target (${overview.periodDuration} hari).'
                              : 'Rutin periksa kondisi tubuh dan volume darah setiap hari saat haid berlangsung.',
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

              // Clinical Guidance / Red Flags for Prolonged Menses
              if (isProlonged) ...[
                const SizedBox(height: AppSizes.space12),
                Container(
                  padding: const EdgeInsets.all(AppSizes.space12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: const Color(0xFFFFE0B2), width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFE65100)),
                          SizedBox(width: 6),
                          Text(
                            'Saran Medis & Kebugaran (Standar ACOG)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overview.prolongedClinicalAdvice,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFFFF3E0)),
                      const SizedBox(height: 6),
                      const Text(
                        'Kapan Perlu Konsultasi Dokter Spesialis (Sp.OG):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...overview.prolongedRedFlags.map((flag) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 11, color: Color(0xFFE65100))),
                              Expanded(
                                child: Text(
                                  flag,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.space14),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRecordTap,
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Catat Kondisi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFFFB8CC)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleConfirmEnded(context, controller),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Haid Sudah Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isProlonged ? const Color(0xFFE65100) : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
