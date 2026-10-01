import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Final step of onboarding with primary call-to-actions.
class OnboardingFinalStep extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const OnboardingFinalStep({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom Cloud & Floral Background
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset(
            'assets/Komponen/bgSplashScreen.png',
            fit: BoxFit.cover,
          ),
        ),

        // Center & Bottom Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space28,
              vertical: AppSizes.space16,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Flower Illustration
                Image.asset(
                  'assets/Komponen/komponenBunga.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSizes.space24),

                // Title
                const Text(
                  'Siap Jaga Dirimu?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSizes.space8),

                // Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Mulai perjalanan sehatmu\nbersama Kalmeda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.space4),
                const Icon(
                  Icons.local_florist_rounded,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const Spacer(flex: 2),

                // Button 1: Mulai Sekarang
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStart,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.space16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF507A),
                            Color(0xFFFF6E94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Mulai Sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.space12),

                // Button 2: Saya sudah punya akun
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLogin,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.space14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                        border: Border.all(
                          color: const Color(0xFFFF85A6),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Saya sudah punya akun',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.space24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
