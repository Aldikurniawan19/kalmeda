import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/core/error/exceptions.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';
import 'package:menstracker/features/record/domain/repositories/record_repository.dart';
import 'package:menstracker/features/record/presentation/controllers/daily_checkin_service.dart';
import 'package:menstracker/features/record/presentation/controllers/record_draft_service.dart';
import 'package:menstracker/features/record/presentation/widgets/flow_selector_section.dart';
import 'package:menstracker/features/record/presentation/widgets/lifestyle_selector_section.dart';
import 'package:menstracker/features/record/presentation/widgets/mood_selector_section.dart';
import 'package:menstracker/features/record/presentation/widgets/notes_input_section.dart';
import 'package:menstracker/features/record/presentation/widgets/record_header.dart';
import 'package:menstracker/features/record/presentation/widgets/record_health_advice_card.dart';
import 'package:menstracker/features/record/presentation/widgets/record_navigation_bar.dart';
import 'package:menstracker/features/record/presentation/widgets/record_stepper_header.dart';
import 'package:menstracker/features/record/presentation/widgets/symptom_selector_section.dart';

/// Screen for recording period flow, mood, physical symptoms, and receiving real-time clinical guidance.
class RecordScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTapped;
  final bool showBottomNav;
  final String? initialNotes;
  final Set<int>? initialSymptoms;

  const RecordScreen({
    super.key,
    this.onNavTapped,
    this.showBottomNav = false,
    this.initialNotes,
    this.initialSymptoms,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final RecordRepository _recordRepository = RecordRepositoryImpl();
  DateTime get _currentDate => DateTime.now();

  int _currentNavIndex = 2;
  int _currentStep = 0;
  late final PageController _pageController;

  int _selectedFlowIndex = 0; // default to 0 (Tidak Ada/Bersih), updated if period is active
  int _selectedMoodIndex = 0; // default 'Bahagia'
  final Set<int> _selectedSymptoms = {};
  int _waterCups = 8;
  int _exerciseIndex = 1; // default 'Ringan'
  bool _isSaving = false;
  late final TextEditingController _notesController;
  // ignore: unused_field
  String? _importedConsultationNote;
  final Set<int> _importedSymptoms = {};

  bool get _isCurrentPeriodActive {
    final homeController = HomeController();
    final overview = homeController.cycleOverview;
    if (overview != null) {
      return overview.isPeriodActive ||
          overview.isPeriodProlonged ||
          overview.currentPhase == CyclePhase.menstrual;
    }

    final profile = homeController.userProfile?.cycleProfile;
    if (profile != null) {
      final dayInfo = CycleEngineService().calculateDayInfo(
        profile: profile,
        targetDate: _currentDate,
      );
      return dayInfo.isPeriodDay || dayInfo.phase == CyclePhase.menstrual;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    HomeController().loadData(silent: true);
    _pageController = PageController(initialPage: _currentStep);
    _notesController = TextEditingController();

    _selectedFlowIndex = _isCurrentPeriodActive ? 3 : 0;

    if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) {
      _notesController.text = widget.initialNotes!;
    }
    if (widget.initialSymptoms != null && widget.initialSymptoms!.isNotEmpty) {
      _importedSymptoms.addAll(widget.initialSymptoms!);
      _selectedSymptoms.addAll(widget.initialSymptoms!);
    }

    RecordDraftService().addListener(_onDraftServiceUpdated);
    _onDraftServiceUpdated();
  }

  void _onDraftServiceUpdated() {
    RecordDraftService().consumeDraft((note, symptoms) {
      if (!mounted) return;
      setState(() {
        if (note.isNotEmpty) {
          _importedConsultationNote = note;
          final existing = _notesController.text.trim();
          if (existing.isEmpty) {
            _notesController.text = note;
          } else if (!existing.contains(note)) {
            _notesController.text = '$existing\n\n$note';
          }
        }
        if (symptoms.isNotEmpty) {
          _importedSymptoms.addAll(symptoms);
          _selectedSymptoms.addAll(symptoms);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keluhan dari sesi konsultasi berhasil dicatat.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _resetForm() {
    _currentStep = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _selectedFlowIndex = _isCurrentPeriodActive ? 3 : 0;
    _selectedMoodIndex = 0;
    _selectedSymptoms.clear();
    _waterCups = 8;
    _exerciseIndex = 1;
    _notesController.clear();
    _importedConsultationNote = null;
    _importedSymptoms.clear();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2 || step == _currentStep) return;
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  @override
  void dispose() {
    RecordDraftService().removeListener(_onDraftServiceUpdated);
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleNavTapped(int index) {
    if (widget.onNavTapped != null) {
      widget.onNavTapped!(index);
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  void _toggleSymptom(int index) {
    setState(() {
      if (_selectedSymptoms.contains(index)) {
        _selectedSymptoms.remove(index);
      } else {
        _selectedSymptoms.add(index);
      }
    });
  }

  Future<void> _handleSaveRecord() async {
    final user = AuthController().currentUser;
    if (user == null || user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masuk terlebih dahulu untuk menyimpan catatan.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final effectiveFlowIndex = _isCurrentPeriodActive ? _selectedFlowIndex : 0;

      final record = CycleRecordModel(
        id: '',
        userId: user.uid,
        date: _currentDate,
        flowIndex: effectiveFlowIndex,
        moodIndex: _selectedMoodIndex,
        symptoms: _selectedSymptoms.toList(),
        waterCups: _waterCups,
        exerciseIndex: _exerciseIndex,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _recordRepository.saveRecord(record);
      DailyCheckinService().markCurrentSlotCompleted();
      DailyCheckinService().syncDailyInactivityNotification();
      await HomeController().loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan harian dan analisis kesehatan berhasil diperbarui.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _resetForm();
      });

      _handleNavTapped(0);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is AppException
          ? e.message
          : 'Terjadi kendala saat menyimpan catatan. Silakan coba kembali.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final isPeriod = _isCurrentPeriodActive;
        final effectiveFlowIndex = isPeriod ? _selectedFlowIndex : 0;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Section: Header & Stepper Indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.space20,
                    AppSizes.space12,
                    AppSizes.space20,
                    AppSizes.space12,
                  ),
                  child: Column(
                    children: [
                      RecordHeader(
                        dateText: DateFormatter.format(_currentDate, includeDayName: true),
                        onBack: () {
                          if (_currentStep > 0) {
                            _previousStep();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            _handleNavTapped(0);
                          }
                        },
                      ),
                      const SizedBox(height: AppSizes.space12),
                      RecordStepperHeader(
                        currentStep: _currentStep,
                        onStepTapped: _goToStep,
                      ),
                    ],
                  ),
                ),

                // Stepper Content Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() => _currentStep = page);
                    },
                    children: [
                      _buildStepZero(isPeriod, effectiveFlowIndex),
                      _buildStepOne(),
                      _buildStepTwo(effectiveFlowIndex),
                    ],
                  ),
                ),

                // Bottom Navigation Action Bar
                RecordNavigationBar(
                  currentStep: _currentStep,
                  totalSteps: 3,
                  isSaving: _isSaving,
                  onPrevious: _previousStep,
                  onNext: _nextStep,
                  onSave: _handleSaveRecord,
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.showBottomNav
              ? HomeBottomNavbar(
                  selectedIndex: _currentNavIndex,
                  onItemTapped: _handleNavTapped,
                )
              : null,
        );
      },
    );
  }

  /// Step 0: Menstruasi & Suasana Hati
  Widget _buildStepZero(bool isPeriod, int effectiveFlowIndex) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowSelectorSection(
            isPeriod: isPeriod,
            selectedFlowIndex: effectiveFlowIndex,
            onFlowSelected: (idx) {
              setState(() => _selectedFlowIndex = idx);
            },
          ),
          const SizedBox(height: AppSizes.space20),
          MoodSelectorSection(
            selectedMoodIndex: _selectedMoodIndex,
            onMoodSelected: (idx) {
              setState(() => _selectedMoodIndex = idx);
            },
          ),
          const SizedBox(height: AppSizes.space24),
        ],
      ),
    );
  }

  /// Step 1: Gejala Fisik & Pola Hidup
  Widget _buildStepOne() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymptomSelectorSection(
            selectedSymptoms: _selectedSymptoms,
            onToggleSymptom: _toggleSymptom,
          ),
          const SizedBox(height: AppSizes.space20),
          LifestyleSelectorSection(
            waterCups: _waterCups,
            onWaterChanged: (cups) {
              setState(() => _waterCups = cups);
            },
            exerciseIndex: _exerciseIndex,
            onExerciseSelected: (idx) {
              setState(() => _exerciseIndex = idx);
            },
          ),
          const SizedBox(height: AppSizes.space24),
        ],
      ),
    );
  }

  /// Step 2: Catatan Tambahan & Panduan Medis Real-Time
  Widget _buildStepTwo(int effectiveFlowIndex) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space20,
        vertical: AppSizes.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotesInputSection(
            controller: _notesController,
          ),
          const SizedBox(height: AppSizes.space20),
          RecordHealthAdviceCard(
            flowIndex: effectiveFlowIndex,
            moodIndex: _selectedMoodIndex,
            symptoms: _selectedSymptoms,
            waterCups: _waterCups,
            exerciseIndex: _exerciseIndex,
          ),
          const SizedBox(height: AppSizes.space24),
        ],
      ),
    );
  }
}
