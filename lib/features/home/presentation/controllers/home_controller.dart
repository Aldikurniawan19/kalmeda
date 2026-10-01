import 'package:flutter/material.dart';
import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';
import 'package:menstracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:menstracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:menstracker/features/record/data/datasources/record_remote_data_source.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Central state management controller powering dynamic Home, Calendar, and Insight modules.
class HomeController extends ChangeNotifier {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;

  final ProfileRepository _profileRepository;
  final RecordRemoteDataSource _recordDataSource;
  final CycleEngineService _engine;

  HomeController._internal({
    ProfileRepository? profileRepository,
    RecordRemoteDataSource? recordDataSource,
    CycleEngineService? engine,
  })  : _profileRepository = profileRepository ?? ProfileRepositoryImpl(),
        _recordDataSource = recordDataSource ?? RecordRemoteDataSourceImpl(),
        _engine = engine ?? CycleEngineService();

  bool _isLoading = false;
  String? _errorMessage;
  UserProfileData? _userProfile;
  CycleOverview? _cycleOverview;

  // Confirmation banner dismiss state per session
  bool _isConfirmationDismissed = false;

  // Calendar interaction state
  DateTime _selectedDate = DateFormatter.dateOnly(DateTime.now());
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  CycleDayInfo? _selectedDayInfo;
  CycleRecordModel? _selectedDateRecord;
  CycleRecordModel? _todayRecord;
  List<CycleRecordModel> _monthRecords = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileData? get userProfile => _userProfile;
  CycleOverview? get cycleOverview => _cycleOverview;
  bool get isConfirmationDismissed => _isConfirmationDismissed;
  DateTime get selectedDate => _selectedDate;
  DateTime get displayedMonth => _displayedMonth;
  CycleDayInfo? get selectedDayInfo => _selectedDayInfo;
  CycleRecordModel? get selectedDateRecord => _selectedDateRecord;
  CycleRecordModel? get todayRecord => _todayRecord;
  List<CycleRecordModel> get monthRecords => _monthRecords;

  /// Returns whether the user has already recorded/checked in their condition today.
  bool get hasCheckinToday {
    final today = DateFormatter.dateOnly(DateTime.now());
    if (_todayRecord != null && DateFormatter.dateOnly(_todayRecord!.date) == today) {
      return true;
    }
    return _monthRecords.any((r) => DateFormatter.dateOnly(r.date) == today);
  }

  /// Loads current user profile and computes full clinical cycle metrics.
  Future<void> loadData({bool silent = false}) async {
    final shouldShowLoading = !silent && _userProfile == null;
    if (shouldShowLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final profile = await _profileRepository.getUserProfile();
      _userProfile = profile;

      _cycleOverview = _engine.calculateOverview(
        profile: profile.cycleProfile,
        referenceDate: DateTime.now(),
      );

      _selectedDayInfo = _engine.calculateDayInfo(
        profile: profile.cycleProfile,
        targetDate: _selectedDate,
      );

      await _fetchRecordsForMonth(_displayedMonth.year, _displayedMonth.month);
      await _fetchRecordForSelectedDate();
      await _fetchRecordForToday();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      // Fallback default profile if unauthenticated or new
      final fallbackCycle = CycleProfileModel(
        trackingGoal: 'predict_period',
        lastPeriodDate: DateTime.now().subtract(const Duration(days: 7)),
        cycleLength: 28,
        periodDuration: 5,
        regularity: 'regular',
        birthDate: DateTime(2000, 1, 1),
      );

      _cycleOverview = _engine.calculateOverview(profile: fallbackCycle);
      _selectedDayInfo = _engine.calculateDayInfo(
        profile: fallbackCycle,
        targetDate: _selectedDate,
      );

      notifyListeners();
    }
  }

  /// User confirms menstruation has started on a specific date (today or custom selected date).
  /// Updates profile in Firestore and automatically recalculates all projections.
  Future<bool> confirmPeriodStarted(DateTime actualStartDate) async {
    if (_userProfile == null) return false;

    try {
      final cleanDate = DateFormatter.dateOnly(actualStartDate);
      final currentCycle = _userProfile!.cycleProfile;

      final updatedCycle = currentCycle.copyWith(
        lastPeriodDate: cleanDate,
        clearLastPeriodEndDate: true,
        updatedAt: DateTime.now(),
      );

      await _profileRepository.updateUserProfile(
        name: _userProfile!.name,
        birthDate: _userProfile!.birthDate,
        cycleProfile: updatedCycle,
      );

      _userProfile = _userProfile!.copyWith(cycleProfile: updatedCycle);
      _cycleOverview = _engine.calculateOverview(profile: updatedCycle);
      _selectedDayInfo = _engine.calculateDayInfo(profile: updatedCycle, targetDate: _selectedDate);
      _isConfirmationDismissed = true;

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// User confirms menstruation ended on a specific date.
  /// Automatically calculates and adapts period duration if valid.
  Future<bool> confirmPeriodEnded(DateTime actualEndDate) async {
    if (_userProfile == null) {
      _errorMessage = 'Profil pengguna belum dimuat.';
      return false;
    }

    try {
      final start = DateFormatter.dateOnly(_userProfile!.cycleProfile.lastPeriodDate);
      final end = DateFormatter.dateOnly(actualEndDate);
      final diff = end.difference(start).inDays + 1;
      final calculatedDuration = diff.clamp(2, 14);

      final updatedCycle = _userProfile!.cycleProfile.copyWith(
        periodDuration: calculatedDuration,
        lastPeriodEndDate: end,
        updatedAt: DateTime.now(),
      );

      await _profileRepository.updateUserProfile(
        name: _userProfile!.name,
        birthDate: _userProfile!.birthDate,
        cycleProfile: updatedCycle,
      );

      _userProfile = _userProfile!.copyWith(cycleProfile: updatedCycle);
      _cycleOverview = _engine.calculateOverview(profile: updatedCycle);
      _selectedDayInfo = _engine.calculateDayInfo(profile: updatedCycle, targetDate: _selectedDate);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Dismisses confirmation card for current session.
  void dismissConfirmation() {
    _isConfirmationDismissed = true;
    notifyListeners();
  }

  /// Selects a date in the calendar and updates agenda and record insights.
  void selectDate(DateTime date) {
    _selectedDate = DateFormatter.dateOnly(date);
    if (_userProfile != null) {
      _selectedDayInfo = _engine.calculateDayInfo(
        profile: _userProfile!.cycleProfile,
        targetDate: _selectedDate,
      );
    }
    _fetchRecordForSelectedDate();
    notifyListeners();
  }

  /// Navigates to next or previous month on the calendar.
  void changeMonth(int delta) {
    _displayedMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + delta,
      1,
    );
    _fetchRecordsForMonth(_displayedMonth.year, _displayedMonth.month);
    notifyListeners();
  }

  /// Jumps back to current day and month.
  void jumpToToday() {
    final now = DateTime.now();
    _selectedDate = DateFormatter.dateOnly(now);
    _displayedMonth = DateTime(now.year, now.month, 1);
    if (_userProfile != null) {
      _selectedDayInfo = _engine.calculateDayInfo(
        profile: _userProfile!.cycleProfile,
        targetDate: _selectedDate,
      );
    }
    _fetchRecordForSelectedDate();
    _fetchRecordsForMonth(_displayedMonth.year, _displayedMonth.month);
    notifyListeners();
  }

  Future<void> _fetchRecordsForMonth(int year, int month) async {
    try {
      _monthRecords = await _recordDataSource.getRecordsByMonth(year, month);
    } catch (_) {
      _monthRecords = [];
    }
  }

  Future<void> _fetchRecordForSelectedDate() async {
    try {
      _selectedDateRecord = await _recordDataSource.getRecordByDate(_selectedDate);
    } catch (_) {
      _selectedDateRecord = null;
    }
  }

  Future<void> _fetchRecordForToday() async {
    try {
      final now = DateTime.now();
      if (DateFormatter.dateOnly(_selectedDate) == DateFormatter.dateOnly(now)) {
        _todayRecord = _selectedDateRecord;
      } else {
        _todayRecord = await _recordDataSource.getRecordByDate(now);
      }
    } catch (_) {
      _todayRecord = null;
    }
  }
}
