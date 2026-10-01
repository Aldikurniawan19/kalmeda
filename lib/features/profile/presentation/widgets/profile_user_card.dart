import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Top profile card with user avatar, details, and 4 summary metrics.
class ProfileUserCard extends StatelessWidget {
  final VoidCallback? onEditProfile;

  const ProfileUserCard({
    super.key,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController(),
      builder: (context, _) {
        final user = AuthController().currentUser;
        final displayName = (user != null && user.name.isNotEmpty) ? user.name : 'Pengguna Kalmeda';
        final displayEmail = (user != null && user.email.isNotEmpty) ? user.email : 'pengguna@kalmeda.app';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFFFE6EE), width: 1.2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF4F7),
                Color(0xFFFFFFFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D79).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top User Details Row
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Camera Edit Badge
                    GestureDetector(
                      onTap: onEditProfile,
                      child: Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF0F5),
                              border: Border.all(
                                color: const Color(0xFFFFDDE6),
                                width: 2.0,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/Komponen/komponenOrang.png',
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.3),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFDDE6),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.space14),

                // User Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Heart
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.space6),
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.space6),

                      // Motivational Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space8,
                          vertical: AppSizes.space4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F4),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.local_florist_rounded,
                              size: 12,
                              color: AppColors.primaryLight,
                            ),
                            SizedBox(width: AppSizes.space4),
                            Text(
                              'Jaga kesehatanmu, kamu hebat!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.space8),

                      // Email Row
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSizes.space6),
                          Expanded(
                            child: Text(
                              displayEmail,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.space4),

                      // Account Status Row
                      Row(
                        children: const [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: AppSizes.space6),
                          Text(
                            'Akun Terhubung',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF6F2F7),
          ),

          // Bottom 4 Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.space14,
              horizontal: AppSizes.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    iconPath: 'assets/icon/darahIsght.png',
                    bgColor: const Color(0xFFFFF0F3),
                    value: '${HomeController().cycleOverview?.periodDuration ?? 5}',
                    label: 'Durasi Haid',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatItem(
                    iconPath: 'assets/icon/kalenderIsght.png',
                    bgColor: const Color(0xFFF3F0FF),
                    value: '${HomeController().cycleOverview?.cycleLength ?? 28}',
                    label: 'Panjang Siklus',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatItem(
                    iconPath: 'assets/icon/iconRiwayat.png',
                    bgColor: const Color(0xFFFFF0F5),
                    value: '${HomeController().monthRecords.length}',
                    label: 'Catatan Bulan Ini',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatItem(
                    iconPath: 'assets/icon/iconMood.png',
                    bgColor: const Color(0xFFFFF0F3),
                    value: 'H-${HomeController().cycleOverview?.currentCycleDay ?? 1}',
                    label: 'Hari Siklus',
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

class _StatItem extends StatelessWidget {
  final String iconPath;
  final Color bgColor;
  final String value;
  final String label;

  const _StatItem({
    required this.iconPath,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(AppSizes.space6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSizes.space6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: const Color(0xFFF3EFF5),
    );
  }
}
