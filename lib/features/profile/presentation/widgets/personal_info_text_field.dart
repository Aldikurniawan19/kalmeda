import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Reusable input field with label, leading icon, and read-only support.
class PersonalInfoTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData prefixIcon;
  final String? hintText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const PersonalInfoTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    required this.prefixIcon,
    this.hintText,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF7F5F8) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
              color: readOnly ? const Color(0xFFECE6ED) : AppColors.inputBorder,
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            readOnly: readOnly,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space14,
                vertical: AppSizes.space12,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: readOnly ? AppColors.textMuted : AppColors.primary,
              ),
              suffixIcon: readOnly
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
