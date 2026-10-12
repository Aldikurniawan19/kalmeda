import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/profile/presentation/controllers/personal_info_controller.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_bottom_bar.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_step_cycle.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_step_health.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_step_personal.dart';
import 'package:menstracker/features/profile/presentation/widgets/personal_info_stepper_header.dart';

/// Screen allowing the user to view and update personal data and menstrual cycle parameters
/// using a structured 3-step stepper interface.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final PersonalInfoController _controller;
  late final PageController _pageController;

  int _currentStep = 0;
  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _controller = PersonalInfoController();
    _pageController = PageController(initialPage: 0);
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _totalSteps) return;
    setState(() {
      _currentStep = stepIndex;
    });
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _handleSave();
    }
  }

  void _handlePrevious() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _handleSave() async {
    final success = await _controller.saveChanges();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi pribadi dan siklus berhasil diperbarui.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Informasi Pribadi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: const Color(0xFFF3EFF4),
                height: 1,
              ),
            ),
          ),
          body: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Top Stepper Indicator
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.space16,
                          AppSizes.space16,
                          AppSizes.space16,
                          AppSizes.space12,
                        ),
                        child: PersonalInfoStepperHeader(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                          onStepTapped: _goToStep,
                        ),
                      ),

                      // Error Banner if present
                      if (_controller.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.space16,
                            vertical: AppSizes.space6,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.space12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.space10),
                                Expanded(
                                  child: Text(
                                    _controller.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Stepper Page Content
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentStep = index;
                            });
                          },
                          children: [
                            _buildStepContainer(
                              child: PersonalInfoStepPersonal(
                                controller: _controller,
                              ),
                            ),
                            _buildStepContainer(
                              child: PersonalInfoStepCycle(
                                controller: _controller,
                              ),
                            ),
                            _buildStepContainer(
                              child: PersonalInfoStepHealth(
                                controller: _controller,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sticky Bottom Action Bar
                      PersonalInfoBottomBar(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        isSaving: _controller.isSaving,
                        onPrevious: _handlePrevious,
                        onNext: _handleNext,
                        onSave: _handleSave,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space12,
      ),
      child: child,
    );
  }
}
