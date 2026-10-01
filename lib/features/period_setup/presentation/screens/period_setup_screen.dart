import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/app_page_route.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/home/presentation/screens/home_screen.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/period_setup/data/repositories/period_setup_repository.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_contraception_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_cycle_length_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_date_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_goal_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_health_conditions_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_period_length_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_progress_header.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_regularity_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_reproductive_status_step.dart';

/// Mandatory multi-step intake stepper for new and unconfigured users.
class PeriodSetupScreen extends StatefulWidget {
  const PeriodSetupScreen({super.key});

  @override
  State<PeriodSetupScreen> createState() => _PeriodSetupScreenState();
}

class _PeriodSetupScreenState extends State<PeriodSetupScreen> {
  final _repository = PeriodSetupRepository();

  int _currentStep = 0;
  static const int _totalSteps = 8;

  // Form states - Basic cycle
  String _trackingGoal = 'predict_period';
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 7));
  int _cycleLength = 28;
  int _periodDuration = 5;
  String _regularity = 'regular';
  DateTime _birthDate = DateTime(2000, 1, 1);

  // Form states - Health profile & lifestyle
  String _reproductiveStatus = 'single';
  int? _menarcheAge = 12;
  String _activityLevel = 'moderate';
  String _contraception = 'none';
  List<String> _gynecologicalConditions = ['none'];
  List<String> _familyMedicalHistory = ['none'];

  bool _isSaving = false;

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _handleSubmit();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final cycleProfile = CycleProfileModel(
        trackingGoal: _trackingGoal,
        lastPeriodDate: _lastPeriodDate,
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        regularity: _regularity,
        birthDate: _birthDate,
        createdAt: DateTime.now(),
      );

      final healthProfile = HealthProfileModel(
        reproductiveStatus: _reproductiveStatus,
        menarcheAge: _menarcheAge,
        activityLevel: _activityLevel,
        contraception: _contraception,
        gynecologicalConditions: _gynecologicalConditions,
        familyMedicalHistory: _familyMedicalHistory,
        createdAt: DateTime.now(),
      );

      await _repository.saveBaselineSetup(
        cycleProfile,
        healthProfile: healthProfile,
      );

      // Update in-memory auth controller state immediately
      AuthController().setSetupCompleted();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil kesehatan dan siklus berhasil disimpan! Selamat datang di Kalmeda.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return SetupGoalStep(
          selectedGoal: _trackingGoal,
          onGoalSelected: (val) => setState(() => _trackingGoal = val),
        );
      case 1:
        return SetupDateStep(
          selectedDate: _lastPeriodDate,
          onDateSelected: (val) => setState(() => _lastPeriodDate = val),
        );
      case 2:
        return SetupCycleLengthStep(
          cycleLength: _cycleLength,
          onCycleLengthChanged: (val) => setState(() => _cycleLength = val),
        );
      case 3:
        return SetupPeriodLengthStep(
          periodDuration: _periodDuration,
          onPeriodDurationChanged: (val) => setState(() => _periodDuration = val),
        );
      case 4:
        return SetupRegularityStep(
          selectedRegularity: _regularity,
          birthDate: _birthDate,
          onRegularitySelected: (val) => setState(() => _regularity = val),
          onBirthDateChanged: (val) => setState(() => _birthDate = val),
        );
      case 5:
        return SetupReproductiveStatusStep(
          selectedStatus: _reproductiveStatus,
          selectedMenarcheAge: _menarcheAge,
          selectedActivityLevel: _activityLevel,
          onStatusSelected: (val) => setState(() => _reproductiveStatus = val),
          onMenarcheAgeChanged: (val) => setState(() => _menarcheAge = val),
          onActivityLevelChanged: (val) => setState(() => _activityLevel = val),
        );
      case 6:
        return SetupContraceptionStep(
          selectedContraception: _contraception,
          onContraceptionSelected: (val) => setState(() => _contraception = val),
        );
      case 7:
        return SetupHealthConditionsStep(
          selectedConditions: _gynecologicalConditions,
          selectedFamilyHistory: _familyMedicalHistory,
          onConditionsChanged: (val) => setState(() => _gynecologicalConditions = val),
          onFamilyHistoryChanged: (val) => setState(() => _familyMedicalHistory = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space24,
            vertical: AppSizes.space16,
          ),
          child: Column(
            children: [
              // Step Progress Header
              SetupProgressHeader(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                onBack: _handleBack,
              ),
              const SizedBox(height: AppSizes.space20),

              // Animated Step Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.space16),

              // Next / Submit CTA Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _handleNext,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
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
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D79).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLastStep ? 'Selesaikan & Mulai' : 'Lanjutkan',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space8),
            ],
          ),
        ),
      ),
    );
  }
}
