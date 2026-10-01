import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Reusable profile settings group card.
class ProfileMenuGroup extends StatelessWidget {
  final String title;
  final List<ProfileMenuItemData> items;

  const ProfileMenuGroup({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space10),

        // Group Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFF6F3F8), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap ?? () {},
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(AppSizes.radiusLarge) : Radius.zero,
                      bottom: isLast ? const Radius.circular(AppSizes.radiusLarge) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                        vertical: AppSizes.space14,
                      ),
                      child: Row(
                        children: [
                          if (item.assetIconPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                item.assetIconPath!,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (item.icon != null)
                            Icon(
                              item.icon!,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: AppSizes.space14),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 50,
                      color: Color(0xFFF7F4F9),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItemData {
  final IconData? icon;
  final String? assetIconPath;
  final String title;
  final VoidCallback? onTap;

  const ProfileMenuItemData({
    this.icon,
    this.assetIconPath,
    required this.title,
    this.onTap,
  });
}
