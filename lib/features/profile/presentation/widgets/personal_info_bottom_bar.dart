import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Bottom action bar for stepper navigation.
/// Displays an icon-only back button and a morphing save button with smooth scale feedback.
class PersonalInfoBottomBar extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSaving;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const PersonalInfoBottomBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isSaving,
    required this.onPrevious,
    required this.onNext,
    required this.onSave,
  });

  @override
  State<PersonalInfoBottomBar> createState() => _PersonalInfoBottomBarState();
}

class _PersonalInfoBottomBarState extends State<PersonalInfoBottomBar> {
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
    final isLastStep = widget.currentStep == widget.totalSteps - 1;
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
            color: Color(0xFFF1ECF3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button (Icon-only with fixed size to prevent any overflow)
            if (widget.currentStep > 0) ...[
              SizedBox(
                width: buttonHeight,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: widget.isSaving ? null : widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFE4DFE7)),
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

            // Next or Save button with morphing animation
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
                                        Text(
                                          isLastStep
                                              ? 'Simpan Perubahan'
                                              : 'Lanjutkan',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (!isLastStep) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ] else ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: Colors.white,
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
