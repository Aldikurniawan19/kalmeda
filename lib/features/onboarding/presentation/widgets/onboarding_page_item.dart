import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Single page layout for onboarding steps 1 to 4.
class OnboardingPageItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final Widget? titleSuffix;
  final String description;
  final int currentIndex;
  final int totalDots;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPageItem({
    super.key,
    required this.imagePath,
    required this.title,
    this.titleSuffix,
    required this.description,
    required this.currentIndex,
    this.totalDots = 4,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space24,
          vertical: AppSizes.space16,
        ),
        child: Column(
          children: [
            // Top "Lewati" Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space8,
                    vertical: AppSizes.space4,
                  ),
                ),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),

            // Center Illustration
            Image.asset(
              imagePath,
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),
            const Spacer(flex: 1),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (titleSuffix != null) ...[
                  const SizedBox(width: AppSizes.space6),
                  titleSuffix!,
                ],
              ],
            ),
            const SizedBox(height: AppSizes.space8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(flex: 2),

            // Bottom Navigation (Dots & Next Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balances the right button for centered dots

                // Centered Dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalDots, (index) {
                    final isSelected = index == currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 8 : 6,
                      height: isSelected ? 8 : 6,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFFFD1DC),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),

                // Next Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNext,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textWhite,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
          ],
        ),
      ),
    );
  }
}
