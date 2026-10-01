import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Information banner card at the bottom of the calendar screen.
class CalendarInfoCard extends StatelessWidget {
  const CalendarInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: const Color(0xFFFFE6EE), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF2F6),
            Color(0xFFFFFFFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D79).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // Left Content
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
              children: const [
                Text(
                  'Informasi Kalender',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppSizes.space6),
                Text(
                  'Pantau siklus menstruasi, hari subur, dan jadwal penting lainnya untuk kesehatanmu.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Right Illustration (komponenKalender.png)
          Positioned(
            right: 2,
            bottom: -4,
            child: Image.asset(
              'assets/Komponen/komponenKalender.png',
              width: 115,
              height: 115,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
