import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/record/presentation/controllers/daily_checkin_service.dart';

/// Strict modal dialog prompting the user to complete their mandatory daily condition check-in.
/// Adheres strictly to `aturan-desain.md` (no emojis, cohesive typography, AA-accessible contrast).
class DailyCheckinDialog extends StatelessWidget {
  final CheckinSlotInfo slotInfo;
  final VoidCallback onProceed;

  const DailyCheckinDialog({
    super.key,
    required this.slotInfo,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Strict modal: cannot dismiss via Android system back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        elevation: 6,
        backgroundColor: AppColors.cardBackground,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space24,
          vertical: AppSizes.space32,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header Badge
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    slotInfo.icon,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space20),

              // Title
              Text(
                slotInfo.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.space8),

              // Subtitle
              Text(
                slotInfo.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.space20),

              // Checklist guidance cards
              Container(
                padding: const EdgeInsets.all(AppSizes.space16),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    _CheckinGuideItem(
                      icon: Icons.water_drop_outlined,
                      text: 'Tingkat hidrasi & konsumsi air putih',
                    ),
                    SizedBox(height: AppSizes.space12),
                    _CheckinGuideItem(
                      icon: Icons.favorite_outline_rounded,
                      text: 'Kondisi fisik, keluhan, & suasana hati',
                    ),
                    SizedBox(height: AppSizes.space12),
                    _CheckinGuideItem(
                      icon: Icons.medical_services_outlined,
                      text: 'Panduan medis & analisis siklus harian',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space24),

              // Action Button (Full Width, No Cancel Button as instructed)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_outlined, size: 20),
                      SizedBox(width: AppSizes.space8),
                      Text(
                        'Catat Sekarang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckinGuideItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CheckinGuideItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSizes.space12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
