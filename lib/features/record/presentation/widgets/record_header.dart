import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/constants/app_text_styles.dart';

/// Top header for Record screen with back button, title, and date navigator.
class RecordHeader extends StatelessWidget {
  final String dateText;
  final VoidCallback? onBack;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;

  const RecordHeader({
    super.key,
    required this.dateText,
    this.onBack,
    this.onPreviousDate,
    this.onNextDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onBack ?? () {},
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
              ),
            ),

            // Title
            const Text(
              'Catat Kondisi',
              style: AppTextStyles.heading2,
            ),

            // Calendar Action Button
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space14),

        // Date Navigator Card
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space14,
            vertical: AppSizes.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFFFE6EE), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onPreviousDate,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: const Padding(
                  padding: EdgeInsets.all(AppSizes.space4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.space6),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onNextDate,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: const Padding(
                  padding: EdgeInsets.all(AppSizes.space4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
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
