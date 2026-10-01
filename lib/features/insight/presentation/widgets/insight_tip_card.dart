import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Dynamic health tip card at the bottom of the insight screen.
class InsightTipCard extends StatelessWidget {
  const InsightTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final dayInfo = controller.cycleOverview?.currentDayInfo;

        final tipTitle = dayInfo != null ? 'Tips ${dayInfo.phaseName}' : 'Tahukah kamu?';
        final tipBody = dayInfo?.nutritionTip ??
            'Tidur yang cukup, olahraga teratur, dan hidrasi yang baik membantu siklus menstruasimu tetap teratur.';

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space14,
            vertical: AppSizes.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFFFE8EF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/Komponen/komponenBunga.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.space2),
                    Text(
                      tipBody,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
