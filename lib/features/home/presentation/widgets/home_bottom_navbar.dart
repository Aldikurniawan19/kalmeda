import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Bottom navigation bar matching the design reference.
class HomeBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  const HomeBottomNavbar({
    super.key,
    this.selectedIndex = 0,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavButton(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped?.call(0),
              ),
              _NavButton(
                icon: Icons.calendar_today_outlined,
                label: 'Kalender',
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped?.call(1),
              ),
              _CenterActionButton(
                label: 'Catat',
                onTap: () => onItemTapped?.call(2),
              ),
              _NavButton(
                icon: Icons.bar_chart_rounded,
                label: 'Insight',
                isSelected: selectedIndex == 3,
                onTap: () => onItemTapped?.call(3),
              ),
              _NavButton(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isSelected: selectedIndex == 4,
                onTap: () => onItemTapped?.call(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.navActive : AppColors.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.space8, vertical: AppSizes.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: AppSizes.space4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CenterActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF628B),
                  Color(0xFFFF4876),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 24,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: AppSizes.space4),
          const Text(
            'Catat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.navInactive,
            ),
          ),
        ],
      ),
    );
  }
}
