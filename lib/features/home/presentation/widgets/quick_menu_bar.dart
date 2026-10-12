import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Quick Menu Bar card with 4 interactive quick action icons.
class QuickMenuBar extends StatelessWidget {
  final VoidCallback? onKalenderTap;
  final VoidCallback? onRiwayatTap;
  final VoidCallback? onMoodTap;
  final VoidCallback? onPengingatTap;

  const QuickMenuBar({
    super.key,
    this.onKalenderTap,
    this.onRiwayatTap,
    this.onMoodTap,
    this.onPengingatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.space16,
        horizontal: AppSizes.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MenuItem(
            label: 'Kalender',
            iconPath: 'assets/icon/iconKalender.png',
            backgroundColor: AppColors.menuKalenderBg,
            onTap: onKalenderTap,
          ),
          _MenuItem(
            label: 'Riwayat',
            iconPath: 'assets/icon/iconRiwayat.png',
            backgroundColor: AppColors.menuRiwayatBg,
            onTap: onRiwayatTap,
          ),
          _MenuItem(
            label: 'Mood',
            iconPath: 'assets/icon/iconMood.png',
            backgroundColor: AppColors.menuMoodBg,
            onTap: onMoodTap,
          ),
          _MenuItem(
            label: 'Pengingat',
            iconPath: 'assets/icon/iconPengingat.png',
            backgroundColor: AppColors.menuPengingatBg,
            onTap: onPengingatTap,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.label,
    required this.iconPath,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space6,
            vertical: AppSizes.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(AppSizes.space4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Image.asset(iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(height: AppSizes.space8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
