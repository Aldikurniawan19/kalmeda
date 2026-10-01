import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/app_page_route.dart';
import 'package:menstracker/features/auth/presentation/screens/login_screen.dart';
import 'package:menstracker/features/auth/presentation/screens/register_screen.dart';

/// Single unified screen for onboarding with smooth element transitions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  static const _onboardingData = [
    {
      'image': 'assets/Komponen/onboarding1.png',
      'title': 'Kenali Siklusmu',
      'description': 'Pantau siklus menstruasi dengan mudah dan akurat setiap hari.',
      'hasHeart': false,
      'hasFlower': false,
    },
    {
      'image': 'assets/Komponen/onboarding3.png',
      'title': 'Prediksi Lebih Baik',
      'description': 'Dapatkan prediksi menstruasi dan masa suburmu.',
      'hasHeart': false,
      'hasFlower': false,
    },
    {
      'image': 'assets/Komponen/onboarding2.png',
      'title': 'Catat & Jaga Dirimu',
      'description': 'Catat mood, gejala, dan pengingat agar tubuhmu selalu terjaga.',
      'hasHeart': false,
      'hasFlower': false,
    },
    {
      'image': 'assets/Komponen/onboarding1.png',
      'title': 'Kamu Berharga',
      'description': 'Kalmeda hadir untuk mendukungmu menjalani hari-hari terbaik.',
      'hasHeart': true,
      'hasFlower': false,
    },
    {
      'image': 'assets/Komponen/komponenBunga.png',
      'title': 'Siap Jaga Dirimu?',
      'description': 'Mulai perjalanan sehatmu\nbersama Kalmeda',
      'hasHeart': false,
      'hasFlower': true,
    },
  ];

  void _nextStep() {
    if (_currentIndex < _onboardingData.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _navigateToRegister();
    }
  }

  void _skipToFinal() {
    setState(() {
      _currentIndex = _onboardingData.length - 1;
    });
  }

  Future<void> _markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('kalmeda_has_seen_onboarding', true);
    } catch (_) {}
  }

  void _navigateToRegister() {
    _markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _navigateToLogin() {
    _markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinalStep = _currentIndex == _onboardingData.length - 1;
    final currentData = _onboardingData[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // Background clouds for the final step with smooth fade
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: isFinalStep ? 0 : -100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isFinalStep ? 1.0 : 0.0,
              child: Image.asset(
                'assets/Komponen/bgSplashScreen.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Interactive Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space24,
                vertical: AppSizes.space16,
              ),
              child: Column(
                children: [
                  // Top "Lewati" Button (hidden on final step)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isFinalStep ? 0.0 : 1.0,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: isFinalStep ? null : _skipToFinal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.space8,
                            vertical: AppSizes.space4,
                          ),
                        ),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),

                  // Center Illustration with Smooth CrossFade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      key: ValueKey<int>(_currentIndex),
                      width: isFinalStep ? 140 : 240,
                      height: isFinalStep ? 140 : 240,
                      child: Image.asset(
                        currentData['image'] as String,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),

                  // Title & Description with Smooth Switcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey<int>(_currentIndex),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentData['title'] as String,
                              style: TextStyle(
                                fontSize: isFinalStep ? 22 : 20,
                                fontWeight: FontWeight.w800,
                                color: isFinalStep ? AppColors.primary : AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (currentData['hasHeart'] as bool) ...[
                              const SizedBox(width: AppSizes.space6),
                              const Icon(
                                Icons.favorite,
                                size: 20,
                                color: AppColors.primaryLight,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSizes.space8),

                        // Subtitle / Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
                          child: Text(
                            currentData['description'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (currentData['hasFlower'] as bool) ...[
                          const SizedBox(height: AppSizes.space4),
                          const Icon(
                            Icons.local_florist_rounded,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Bottom Action Area with Smooth Switcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isFinalStep
                        ? Column(
                            key: const ValueKey('final_buttons'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Button 1: Mulai Sekarang
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _navigateToRegister,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: AppSizes.space16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF507A),
                                          Color(0xFFFF6E94),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Mulai Sekarang',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.space12),

                              // Button 2: Saya sudah punya akun
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _navigateToLogin,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: AppSizes.space14),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                                      border: Border.all(
                                        color: const Color(0xFFFF85A6),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Saya sudah punya akun',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('step_dots_nav'),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48), // Balance right button

                              // Animated Dots Indicator
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(4, (index) {
                                  final isSelected = index == _currentIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: isSelected ? 8 : 6,
                                    height: isSelected ? 8 : 6,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : const Color(0xFFFFD1DC),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),

                              // Next Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _nextStep,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.textWhite,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSizes.space16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
