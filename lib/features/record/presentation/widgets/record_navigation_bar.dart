import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Bottom action navigation bar for multi-step record flow.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class RecordNavigationBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSaving;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const RecordNavigationBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.isSaving,
    required this.onPrevious,
    required this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFirstStep = currentStep == 0;
    final bool isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF0EBEF),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back Button (shown on steps > 0)
            if (!isFirstStep) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onPrevious,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.space14),
                    side: const BorderSide(color: Color(0xFFE4DFE4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space12),
            ],

            // Next or Save CTA
            Expanded(
              flex: isFirstStep ? 1 : 3,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSaving ? null : (isLastStep ? onSave : onNext),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.space14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF507A),
                          Color(0xFFFF6E94),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D79).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLastStep) ...[
                          if (isSaving)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textWhite,
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.textWhite,
                            ),
                          const SizedBox(width: AppSizes.space8),
                          Text(
                            isSaving ? 'Menyimpan...' : 'Simpan Catatan',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ] else ...[
                          Text(
                            isFirstStep ? 'Lanjut ke Gejala' : 'Lanjut ke Catatan',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(width: AppSizes.space6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.textWhite,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
