import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Bottom action navigation bar for multi-step record flow.
/// Features an icon-only back button and a morphing save button with scale animation.
class RecordNavigationBar extends StatefulWidget {
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
  State<RecordNavigationBar> createState() => _RecordNavigationBarState();
}

class _RecordNavigationBarState extends State<RecordNavigationBar> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isSaving) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirstStep = widget.currentStep == 0;
    final bool isLastStep = widget.currentStep == widget.totalSteps - 1;
    const double buttonHeight = 48.0;

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
            // Back Button (Icon-only, shown on steps > 0)
            if (!isFirstStep) ...[
              SizedBox(
                width: buttonHeight,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: widget.isSaving ? null : widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFE4DFE4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space12),
            ],

            // Next / Save CTA with morphing loading animation
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fullWidth = constraints.maxWidth;
                    final targetWidth =
                        (isLastStep && widget.isSaving) ? buttonHeight : fullWidth;

                    return AnimatedScale(
                      scale: _isPressed ? 0.96 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      child: GestureDetector(
                        onTapDown: _handleTapDown,
                        onTapUp: _handleTapUp,
                        onTapCancel: _handleTapCancel,
                        onTap: widget.isSaving
                            ? null
                            : (isLastStep ? widget.onSave : widget.onNext),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          width: targetWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF507A),
                                Color(0xFFFF6E94),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              (isLastStep && widget.isSaving)
                                  ? buttonHeight / 2
                                  : AppSizes.radiusMedium,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D79).withValues(
                                  alpha: widget.isSaving ? 0.20 : 0.32,
                                ),
                                blurRadius: widget.isSaving ? 8 : 12,
                                offset: Offset(0, widget.isSaving ? 3 : 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: (isLastStep && widget.isSaving)
                                  ? const SizedBox(
                                      key: ValueKey('saving_spinner'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.textWhite,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      key: ValueKey<int>(widget.currentStep),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isLastStep) ...[
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 18,
                                            color: AppColors.textWhite,
                                          ),
                                          const SizedBox(width: AppSizes.space8),
                                          const Text(
                                            'Simpan Catatan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textWhite,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            isFirstStep
                                                ? 'Lanjut ke Gejala'
                                                : 'Lanjut ke Catatan',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textWhite,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(width: AppSizes.space6),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: AppColors.textWhite,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
