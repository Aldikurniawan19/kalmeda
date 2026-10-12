import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Modern, sleek, and minimalist stepper header.
/// Features a segmented progress bar and interactive tab chips.
class PersonalInfoStepperHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int> onStepTapped;

  const PersonalInfoStepperHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.onStepTapped,
  });

  static const List<_StepMeta> _steps = [
    _StepMeta(title: 'Data Diri', icon: Icons.person_rounded),
    _StepMeta(title: 'Siklus Haid', icon: Icons.water_drop_rounded),
    _StepMeta(title: 'Kesehatan', icon: Icons.health_and_safety_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Segmented Progress Bar (Instagram / Modern Flow style)
          Row(
            children: List.generate(totalSteps, (index) {
              final isFilled = index <= currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onStepTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 6.0 : 0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AppColors.primary
                            : const Color(0xFFEEE7EE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.space10),

          // Minimalist Step Pills
          Row(
            children: List.generate(totalSteps, (index) {
              final isPassed = index < currentStep;
              final isActive = index == currentStep;
              final step = _steps[index];

              return Expanded(
                child: InkWell(
                  onTap: () => onStepTapped(index),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.space8,
                      horizontal: AppSizes.space4,
                    ),
                    margin: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 4.0 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primarySoft
                          : (isPassed
                              ? const Color(0xFFF9F7FA)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFFFBCCF)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPassed ? Icons.check_rounded : step.icon,
                          size: 14,
                          color: isActive
                              ? AppColors.primary
                              : (isPassed
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.textMuted),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            step.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : (isPassed
                                      ? FontWeight.w600
                                      : FontWeight.w500),
                              color: isActive
                                  ? AppColors.primary
                                  : (isPassed
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepMeta {
  final String title;
  final IconData icon;

  const _StepMeta({required this.title, required this.icon});
}
