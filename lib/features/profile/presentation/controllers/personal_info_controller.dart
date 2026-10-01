import 'package:flutter/material.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';
import 'package:menstracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:menstracker/features/profile/domain/repositories/profile_repository.dart';

/// Controller managing personal profile, menstrual cycle preferences, and health profile.
class PersonalInfoController extends ChangeNotifier {
  final ProfileRepository _repository;

  PersonalInfoController({
    ProfileRepository? repository,
  }) : _repository = repository ?? ProfileRepositoryImpl();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  UserProfileData? _profileData;

  // Form State - Account & Cycle
  final TextEditingController nameController = TextEditingController();
  String _email = '';
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _trackingGoal = 'predict_period';
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 7));
  int _cycleLength = 28;
  int _periodDuration = 5;
  String _regularity = 'regular';

  // Form State - Health Profile
  String _reproductiveStatus = 'single';
  int? _menarcheAge = 12;
  String _activityLevel = 'moderate';
  String _contraception = 'none';
  List<String> _gynecologicalConditions = ['none'];
  List<String> _familyMedicalHistory = ['none'];

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  UserProfileData? get profileData => _profileData;

  String get email => _email;
  DateTime get birthDate => _birthDate;
  String get trackingGoal => _trackingGoal;
  DateTime get lastPeriodDate => _lastPeriodDate;
  int get cycleLength => _cycleLength;
  int get periodDuration => _periodDuration;
  String get regularity => _regularity;

  String get reproductiveStatus => _reproductiveStatus;
  int? get menarcheAge => _menarcheAge;
  String get activityLevel => _activityLevel;
  String get contraception => _contraception;
  List<String> get gynecologicalConditions => _gynecologicalConditions;
  List<String> get familyMedicalHistory => _familyMedicalHistory;

  /// Loads current user profile, cycle configuration, and health profile from data source.
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.getUserProfile();
      _profileData = profile;

      nameController.text = profile.name;
      _email = profile.email;
      _birthDate = profile.birthDate;
      _trackingGoal = profile.cycleProfile.trackingGoal;
      _lastPeriodDate = profile.cycleProfile.lastPeriodDate;
      _cycleLength = profile.cycleProfile.cycleLength;
      _periodDuration = profile.cycleProfile.periodDuration;
      _regularity = profile.cycleProfile.regularity;

      final hp = profile.healthProfile;
      if (hp != null) {
        _reproductiveStatus = hp.reproductiveStatus;
        _menarcheAge = hp.menarcheAge;
        _activityLevel = hp.activityLevel;
        _contraception = hp.contraception;
        _gynecologicalConditions = List<String>.from(hp.gynecologicalConditions);
        _familyMedicalHistory = List<String>.from(hp.familyMedicalHistory);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void updateBirthDate(DateTime date) {
    _birthDate = date;
    notifyListeners();
  }

  void updateTrackingGoal(String goal) {
    _trackingGoal = goal;
    notifyListeners();
  }

  void updateLastPeriodDate(DateTime date) {
    _lastPeriodDate = date;
    notifyListeners();
  }

  void updateCycleLength(int length) {
    _cycleLength = length;
    notifyListeners();
  }

  void updatePeriodDuration(int duration) {
    _periodDuration = duration;
    notifyListeners();
  }

  void updateRegularity(String regularity) {
    _regularity = regularity;
    notifyListeners();
  }

  void updateReproductiveStatus(String status) {
    _reproductiveStatus = status;
    notifyListeners();
  }

  void updateMenarcheAge(int? age) {
    _menarcheAge = age;
    notifyListeners();
  }

  void updateActivityLevel(String level) {
    _activityLevel = level;
    notifyListeners();
  }

  void updateContraception(String contraception) {
    _contraception = contraception;
    notifyListeners();
  }

  void updateGynecologicalConditions(List<String> conditions) {
    _gynecologicalConditions = List<String>.from(conditions);
    notifyListeners();
  }

  void updateFamilyMedicalHistory(List<String> history) {
    _familyMedicalHistory = List<String>.from(history);
    notifyListeners();
  }

  /// Validates and saves updated profile information.
  Future<bool> saveChanges() async {
    final trimmedName = nameController.text.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Nama lengkap tidak boleh kosong.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedCycleProfile = CycleProfileModel(
        trackingGoal: _trackingGoal,
        lastPeriodDate: _lastPeriodDate,
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        regularity: _regularity,
        birthDate: _birthDate,
        updatedAt: DateTime.now(),
      );

      final updatedHealthProfile = HealthProfileModel(
        reproductiveStatus: _reproductiveStatus,
        menarcheAge: _menarcheAge,
        activityLevel: _activityLevel,
        contraception: _contraception,
        gynecologicalConditions: _gynecologicalConditions,
        familyMedicalHistory: _familyMedicalHistory,
        updatedAt: DateTime.now(),
      );

      await _repository.updateUserProfile(
        name: trimmedName,
        birthDate: _birthDate,
        cycleProfile: updatedCycleProfile,
        healthProfile: updatedHealthProfile,
      );

      // Refresh global authentication state and cycle engine
      await AuthController().checkAuthStatus();
      await HomeController().loadData();

      _profileData = _profileData?.copyWith(
        name: trimmedName,
        birthDate: _birthDate,
        cycleProfile: updatedCycleProfile,
        healthProfile: updatedHealthProfile,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Gagal menyimpan perubahan: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}

