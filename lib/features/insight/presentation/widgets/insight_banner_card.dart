import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Top banner card personalized with the user's tracking goal and phase.
class InsightBannerCard extends StatelessWidget {
  const InsightBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final overview = controller.cycleOverview;
        final goal = overview?.trackingGoal ?? 'predict_period';

        String title;
        String subtitle;

        switch (goal) {
          case 'fertility_ovulation':
            title = 'Fokus Kesuburan & Ovulasi';
            subtitle =
                'Pantau masa subur dan hari ovulasi untuk perencanaan kehamilan yang optimal.';
            break;
          case 'symptom_health':
            title = 'Pantau Gejala & Kesehatan';
            subtitle =
                'Kenali pola perubahan mood, energi, dan respon fisik tubuh di setiap fase.';
            break;
          case 'predict_period':
          default:
            title = 'Prediksi Menstruasi Akurat';
            subtitle =
                'Insight medis membantumu mengetahui jadwal haid mendatang dengan tepat waktu.';
            break;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFFFE6EE), width: 1.2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF2F6), Color(0xFFFFFFFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D79).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Illustration on the right
              Positioned(
                top: -24,
                right: 0,
                child: Image.asset(
                  'assets/Komponen/orangIsght.png',
                  width: 145,
                  height: 145,
                  fit: BoxFit.contain,
                ),
              ),

              // Text content on the left
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.space16,
                  top: AppSizes.space16,
                  bottom: AppSizes.space16,
                  right: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.space4),
                        const Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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
