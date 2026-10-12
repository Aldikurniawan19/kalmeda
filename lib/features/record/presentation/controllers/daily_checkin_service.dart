import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/features/record/data/datasources/record_remote_data_source.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';
import 'package:menstracker/features/record/presentation/widgets/daily_checkin_dialog.dart';

/// Active time slots for daily condition check-ins.
enum CheckinTimeSlot {
  morning,
  afternoon,
  evening,
  none,
}

/// Metadata and UI information for a specific check-in time slot.
class CheckinSlotInfo {
  final CheckinTimeSlot slot;
  final String title;
  final String subtitle;
  final IconData icon;

  const CheckinSlotInfo({
    required this.slot,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Service managing the logic for prompting users to fill in their daily condition
/// at morning (08:00), afternoon (12:00), and evening (16:00-20:59), as well as
/// scheduling inactivity notifications if the app was never opened all day.
class DailyCheckinService {
  static final DailyCheckinService _instance = DailyCheckinService._internal();
  factory DailyCheckinService() => _instance;

  final RecordRemoteDataSource _recordDataSource;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  DailyCheckinService._internal({
    RecordRemoteDataSource? recordDataSource,
    FirebaseAuth? auth,
    NotificationService? notificationService,
  })  : _recordDataSource = recordDataSource ?? RecordRepositoryImpl(),
        _auth = auth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService();

  bool _isDialogShowing = false;
  final Set<String> _completedSlotsInSession = <String>{};

  /// Evaluates which time slot corresponds to the given [dateTime] (defaults to DateTime.now()).
  CheckinTimeSlot getCurrentSlot([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final hour = now.hour;

    // Morning: 08:00 - 11:59
    if (hour >= 8 && hour < 12) {
      return CheckinTimeSlot.morning;
    }
    // Afternoon: 12:00 - 15:59
    if (hour >= 12 && hour < 16) {
      return CheckinTimeSlot.afternoon;
    }
    // Evening / sunset: 16:00 - 20:59
    if (hour >= 16 && hour < 21) {
      return CheckinTimeSlot.evening;
    }
    // Outside active slots (21:00 - 07:59)
    return CheckinTimeSlot.none;
  }

  /// Returns user-friendly metadata for the given [slot].
  CheckinSlotInfo getSlotInfo(CheckinTimeSlot slot) {
    switch (slot) {
      case CheckinTimeSlot.morning:
        return const CheckinSlotInfo(
          slot: CheckinTimeSlot.morning,
          title: 'Catatan Kondisi Pagi',
          subtitle: 'Mulai harimu dengan mencatat gejala fisik, suasana hati, dan kebutuhan tubuhmu.',
          icon: Icons.wb_sunny_outlined,
        );
      case CheckinTimeSlot.afternoon:
        return const CheckinSlotInfo(
          slot: CheckinTimeSlot.afternoon,
          title: 'Catatan Kondisi Siang',
          subtitle: 'Perbarui tingkat hidrasi, keluhan fisik, dan energi tubuhmu siang ini.',
          icon: Icons.wb_cloudy_outlined,
        );
      case CheckinTimeSlot.evening:
        return const CheckinSlotInfo(
          slot: CheckinTimeSlot.evening,
          title: 'Catatan Kondisi Sore',
          subtitle: 'Evaluasi kondisi fisik dan suasana hatimu sebelum menutup aktivitas hari ini.',
          icon: Icons.nights_stay_outlined,
        );
      case CheckinTimeSlot.none:
        return const CheckinSlotInfo(
          slot: CheckinTimeSlot.none,
          title: 'Catatan Kondisi Harian',
          subtitle: 'Perbarui catatan kondisi tubuh dan suasana hatimu.',
          icon: Icons.assignment_outlined,
        );
    }
  }

  /// Generates a unique key for the slot of the day, e.g. "2026-09-04_morning".
  String _slotKey(DateTime date, CheckinTimeSlot slot) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${dateStr}_${slot.name}';
  }

  /// Calculates the start DateTime of the given [slot] on [date].
  DateTime _getSlotStartTime(DateTime date, CheckinTimeSlot slot) {
    switch (slot) {
      case CheckinTimeSlot.morning:
        return DateTime(date.year, date.month, date.day, 8, 0);
      case CheckinTimeSlot.afternoon:
        return DateTime(date.year, date.month, date.day, 12, 0);
      case CheckinTimeSlot.evening:
        return DateTime(date.year, date.month, date.day, 16, 0);
      case CheckinTimeSlot.none:
        return DateTime(date.year, date.month, date.day, 0, 0);
    }
  }

  /// Determines if the current user needs to be prompted for the active time slot.
  Future<bool> shouldPromptCheckin([DateTime? testDate]) async {
    final now = testDate ?? DateTime.now();
    final slot = getCurrentSlot(now);

    if (slot == CheckinTimeSlot.none) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    final key = _slotKey(now, slot);
    if (_completedSlotsInSession.contains(key)) return false;

    try {
      final existingRecord = await _recordDataSource.getRecordByDate(now);
      if (existingRecord == null) {
        // No record exists for today at all
        return true;
      }

      final recordTime = existingRecord.updatedAt ?? existingRecord.createdAt;
      if (recordTime == null) {
        return true;
      }

      final slotStartTime = _getSlotStartTime(now, slot);
      // If the record was updated before the start of this slot, prompt user to update for this slot
      if (recordTime.isBefore(slotStartTime)) {
        return true;
      }

      // Record was updated during or after this slot started
      _completedSlotsInSession.add(key);
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if prompt is needed and displays the strict modal dialog if so.
  Future<void> checkAndPromptIfNeeded(
    BuildContext context, {
    required VoidCallback onNavigateToRecord,
  }) async {
    if (_isDialogShowing) return;

    final shouldPrompt = await shouldPromptCheckin();
    if (!shouldPrompt || !context.mounted) return;

    final slot = getCurrentSlot();
    final slotInfo = getSlotInfo(slot);

    _isDialogShowing = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // Strict modal: cannot dismiss by tapping outside
        builder: (dialogCtx) => DailyCheckinDialog(
          slotInfo: slotInfo,
          onProceed: () {
            Navigator.of(dialogCtx).pop();
            markCurrentSlotCompleted();
            onNavigateToRecord();
          },
        ),
      );
    } finally {
      _isDialogShowing = false;
    }
  }

  /// Marks the current slot as recorded to prevent repeated prompting during the current session.
  void markCurrentSlotCompleted([DateTime? testDate]) {
    final now = testDate ?? DateTime.now();
    final slot = getCurrentSlot(now);
    if (slot != CheckinTimeSlot.none) {
      _completedSlotsInSession.add(_slotKey(now, slot));
    }
  }

  /// Synchronizes scheduled inactivity notification.
  /// If user has already completed a record today, schedules the inactivity reminder for tomorrow.
  /// If not yet recorded, schedules for 19:30 today (or next occurrence).
  Future<void> syncDailyInactivityNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final record = await _recordDataSource.getRecordByDate(now);

      if (record != null) {
        // User already opened and recorded today!
        // Reschedule inactivity reminder for tomorrow 19:30 so it won't trigger tonight
        await _notificationService.scheduleDailyCheckinReminder(
          hour: 19,
          minute: 30,
          title: 'Bagaimana Kondisimu Hari Ini?',
          body: 'Kamu belum mencatat kondisi tubuh dan suasana hatimu hari ini. Buka Kalmeda untuk mencatat sekarang.',
        );
        debugPrint('Inactivity notification synced for upcoming cycle (record present today)');
      } else {
        // User has not recorded yet today. Ensure reminder at 19:30 is active
        await _notificationService.scheduleDailyCheckinReminder(
          hour: 19,
          minute: 30,
          title: 'Bagaimana Kondisimu Hari Ini?',
          body: 'Kamu belum mencatat kondisi tubuh dan suasana hatimu hari ini. Buka Kalmeda untuk mencatat sekarang.',
        );
        debugPrint('Inactivity notification scheduled for 19:30 today');
      }
    } catch (e) {
      debugPrint('Error syncing daily inactivity notification: $e');
    }
  }
}
