import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_text_styles.dart';

/// App bar / top header for Insight screen with back button and calendar action.
class InsightHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const InsightHeader({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.iconButtonBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onBack ?? () {},
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
          ),
        ),

        // Title
        const Text(
          'Insight',
          style: AppTextStyles.heading2,
        ),

        // Calendar button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.iconButtonBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
