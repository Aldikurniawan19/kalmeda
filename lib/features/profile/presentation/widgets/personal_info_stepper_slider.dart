import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Combined slider and stepper counter with clinical reference badge.
/// Prevents overflow with flexible text layout and provides value clamping.
class PersonalInfoStepperSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final String? clinicalNote;
  final ValueChanged<int> onChanged;

  const PersonalInfoStepperSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.clinicalNote,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max);
    final divisions = (max - min) > 0 ? (max - min) : 1;

    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.inputBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label & Value Stepper Controls (Protected from horizontal overflow)
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: clampedValue > min ? () => onChanged(clampedValue - 1) : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space8,
                      vertical: AppSizes.space4,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.space6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: const Color(0xFFFFD1DE), width: 1.0),
                    ),
                    child: Text(
                      '$clampedValue $unit',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: clampedValue < max ? () => onChanged(clampedValue + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFFFD6E3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: clampedValue.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions,
              onChanged: (val) => onChanged(val.round()),
            ),
          ),

          if (clinicalNote != null) ...[
            const SizedBox(height: AppSizes.space2),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.space4),
                Expanded(
                  child: Text(
                    clinicalNote!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFF7F4F7) : const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: isEnabled ? const Color(0xFFE4DFE6) : const Color(0xFFF0EDF2),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
