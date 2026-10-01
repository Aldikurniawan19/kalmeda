import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/constants/app_text_styles.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';

/// Top header widget with dynamic greetings and illustration.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController(),
      builder: (context, _) {
        final user = AuthController().currentUser;
        final firstName = (user != null && user.name.isNotEmpty)
            ? user.name.trim().split(' ').first
            : 'Teman';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Woman illustration positioned on the right
            Positioned(
              top: -6,
              right: -2,
              child: Image.asset(
                'assets/Komponen/komponenOrang.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),

            // Left greeting text with right margin to prevent collision with illustration
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.space8,
                bottom: AppSizes.space16,
                right: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Halo, $firstName',
                          style: AppTextStyles.heading1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space6),
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Flexible(
                        child: Text(
                          'Jaga kesehatanmu, kamu hebat!',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      SizedBox(width: AppSizes.space4),
                      Icon(
                        Icons.local_florist_rounded,
                        color: AppColors.primaryLight,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
