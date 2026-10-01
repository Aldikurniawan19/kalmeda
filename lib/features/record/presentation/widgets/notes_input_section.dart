import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Notes input section for custom daily notes.
class NotesInputSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesInputSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan Pribadi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.space4),
        const Text(
          'Tuliskan catatan khusus atau keluhan lainnya hari ini',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.space12),

        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: const Color(0xFFF4EFF5), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Misal: Nyeri sedikit mereda setelah minum teh hangat...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppSizes.space14),
            ),
          ),
        ),
      ],
    );
  }
}
