import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Controller managing menstrual and wellness reminder notification preferences and local notification triggers.
class ReminderController extends ChangeNotifier {
  static final ReminderController _instance = ReminderController._internal();
  factory ReminderController() => _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService = NotificationService();

  /// SharedPreferences key for last app open timestamp.
  static const String _lastOpenKey = 'kalmeda_last_open_ms';

  ReminderController._internal({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isSaving = false;

  // In-memory toggle states
  bool _periodReminder = true;
  bool _fertileReminder = true;
  bool _waterReminder = true;
  bool _padReminder = true;
  bool _vitaminReminder = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get periodReminder => _periodReminder;
  bool get fertileReminder => _fertileReminder;
  bool get waterReminder => _waterReminder;
  bool get padReminder => _padReminder;
  bool get vitaminReminder => _vitaminReminder;

  String? get _uid => _auth.currentUser?.uid;

  /// Loads stored reminder preferences from Firestore or keeps in-memory state.
  Future<void> loadPreferences() async {
    final uid = _uid;
    if (uid == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('reminders')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _periodReminder = data['periodReminder'] as bool? ?? true;
        _fertileReminder = data['fertileReminder'] as bool? ?? true;
        _waterReminder = data['waterReminder'] as bool? ?? true;
        _padReminder = data['padReminder'] as bool? ?? true;
        _vitaminReminder = data['vitaminReminder'] as bool? ?? false;
      }
    } catch (_) {
      // Keep existing memory defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets toggle state in-memory before user clicks save.
  void setReminderState({
    bool? period,
    bool? fertile,
    bool? water,
    bool? pad,
    bool? vitamin,
  }) {
    if (period != null) _periodReminder = period;
    if (fertile != null) _fertileReminder = fertile;
    if (water != null) _waterReminder = water;
    if (pad != null) _padReminder = pad;
    if (vitamin != null) _vitaminReminder = vitamin;
    notifyListeners();
  }

  /// Legacy support for direct toggle if needed.
  Future<void> toggleReminder({
    bool? period,
    bool? fertile,
    bool? water,
    bool? pad,
    bool? vitamin,
  }) async {
    setReminderState(
      period: period,
      fertile: fertile,
      water: water,
      pad: pad,
      vitamin: vitamin,
    );
  }

  /// Saves all current reminder preferences to Firestore and schedules real notifications.
  Future<bool> savePreferences() async {
    _isSaving = true;
    notifyListeners();

    try {
      // 1. Request device notification permission if any reminder is enabled
      final isAnyEnabled =
          _periodReminder ||
          _fertileReminder ||
          _waterReminder ||
          _padReminder ||
          _vitaminReminder;
      if (isAnyEnabled) {
        await _notificationService.requestPermissions();
      }

      // 2. Persist to Firestore
      final uid = _uid;
      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('reminders')
            .set({
              'periodReminder': _periodReminder,
              'fertileReminder': _fertileReminder,
              'waterReminder': _waterReminder,
              'padReminder': _padReminder,
              'vitaminReminder': _vitaminReminder,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      // 3. Synchronize actual scheduled notifications
      await syncScheduledNotifications();

      return true;
    } catch (e) {
      debugPrint('Error saving reminder preferences: $e');
      // Even if firestore fails (e.g. offline), we still schedule notifications locally
      await syncScheduledNotifications();
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Synchronizes all scheduled device notifications based on active cycle information.
  Future<void> syncScheduledNotifications() async {
    final overview = HomeController().cycleOverview;

    // --- Existing Reminder: Period Reminder (H-2 before next period date at 09:00 AM) ---
    if (_periodReminder && overview != null) {
      final periodTarget = overview.nextPeriodDate.subtract(
        const Duration(days: 2),
      );
      final scheduledDate = DateTime(
        periodTarget.year,
        periodTarget.month,
        periodTarget.day,
        9,
        0,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleCycleReminder(
          id: NotificationService.idPeriodReminder,
          title: 'Perkiraan Haid 2 Hari Lagi',
          body:
              'Siklus menstruasi diperkirakan dimulai dalam 2 hari. Siapkan pembalut dan jaga kebugaran tubuhmu.',
          scheduledDate: scheduledDate,
        );
      }
    } else {
      await _notificationService.cancel(NotificationService.idPeriodReminder);
    }

    // --- NEW 1: Pre-Period Reminder (H-4 before estimated period at 09:00 AM) ---
    if (_periodReminder && overview != null) {
      final prePeriodTarget = overview.nextPeriodDate.subtract(
        const Duration(days: 4),
      );
      final scheduledDate = DateTime(
        prePeriodTarget.year,
        prePeriodTarget.month,
        prePeriodTarget.day,
        9,
        0,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleCycleReminder(
          id: NotificationService.idPrePeriodReminder,
          title: 'Perkiraan Haid 4 Hari Lagi',
          body:
              'Menstruasi diperkirakan akan datang dalam 4 hari. Persiapkan kebutuhan kebersihan dan perhatikan perubahan tubuhmu.',
          scheduledDate: scheduledDate,
          payload: 'open_home',
        );
      }
    } else {
      await _notificationService.cancel(
        NotificationService.idPrePeriodReminder,
      );
    }

    // --- NEW 2: Daily Morning Checkin during Period (08:00 AM) ---
    // Only active when user is currently in menstrual phase
    if (overview != null && overview.isPeriodActive) {
      final now = DateTime.now();
      final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 8, 0);

      await _notificationService.scheduleCheckinReminder(
        id: NotificationService.idPeriodDailyMorning,
        title: 'Catat Kondisi Harimu',
        body:
            'Kamu sedang dalam masa menstruasi. Catat gejala fisik, suasana hati, dan intensitas darahmu pagi ini.',
        scheduledDate: tomorrowMorning,
        payload: 'open_record',
      );
    } else {
      await _notificationService.cancel(
        NotificationService.idPeriodDailyMorning,
      );
    }

    // --- NEW 3: Daily Afternoon Reminder during Period (16:00 PM) ---
    // Reminds user to open app and record if they haven't since morning
    if (overview != null && overview.isPeriodActive) {
      final now = DateTime.now();
      // If past 16:00 today, schedule for tomorrow; otherwise today
      DateTime afternoonTarget = DateTime(now.year, now.month, now.day, 16, 0);
      if (afternoonTarget.isBefore(now)) {
        afternoonTarget = DateTime(now.year, now.month, now.day + 1, 16, 0);
      }

      await _notificationService.scheduleCheckinReminder(
        id: NotificationService.idPeriodDailyAfternoon,
        title: 'Belum Mencatat Hari Ini?',
        body:
            'Kamu belum membuka Kalmeda hari ini. Luangkan sebentar untuk mencatat kondisi menstruasimu agar pantauan tetap akurat.',
        scheduledDate: afternoonTarget,
        payload: 'open_record',
      );
    } else {
      await _notificationService.cancel(
        NotificationService.idPeriodDailyAfternoon,
      );
    }

    // --- NEW 4: Period Ending Soon (H-2 before estimated period end at 09:00 AM) ---
    if (_periodReminder && overview != null && overview.isPeriodActive) {
      // Estimated period end = lastPeriodDate + periodDuration
      final profile = HomeController().userProfile?.cycleProfile;
      if (profile != null) {
        final periodStart = profile.lastPeriodDate;
        final periodEnd = periodStart.add(
          Duration(days: profile.periodDuration),
        );
        final endingSoonTarget = periodEnd.subtract(const Duration(days: 2));
        final scheduledDate = DateTime(
          endingSoonTarget.year,
          endingSoonTarget.month,
          endingSoonTarget.day,
          9,
          0,
        );

        if (scheduledDate.isAfter(DateTime.now())) {
          await _notificationService.scheduleCycleReminder(
            id: NotificationService.idPeriodEndingSoon,
            title: 'Menstruasi Diperkirakan Segera Selesai',
            body:
                'Masa menstruasimu diperkirakan akan berakhir dalam 2 hari. Pastikan untuk mengonfirmasi tanggal berakhir di Kalmeda.',
            scheduledDate: scheduledDate,
            payload: 'open_home',
          );
        }
      }
    } else {
      await _notificationService.cancel(NotificationService.idPeriodEndingSoon);
    }

    // --- Existing: Fertile Window & Ovulation Reminder (at 09:00 AM on fertile window start) ---
    if (_fertileReminder && overview != null) {
      final fertileTarget = overview.fertileWindowStart;
      final scheduledDate = DateTime(
        fertileTarget.year,
        fertileTarget.month,
        fertileTarget.day,
        9,
        0,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleCycleReminder(
          id: NotificationService.idFertileReminder,
          title: 'Masa Subur Dimulai Hari Ini',
          body:
              'Hari ini kamu memasuki jendela masa subur dengan peluang pembuahan optimal.',
          scheduledDate: scheduledDate,
        );
      }
    } else {
      await _notificationService.cancel(NotificationService.idFertileReminder);
    }

    // --- Existing: Daily Water Hydration Reminder (Daily at 10:00 AM) ---
    if (_waterReminder) {
      await _notificationService.scheduleDailyWellnessReminder(
        id: NotificationService.idWaterReminder,
        title: 'Waktunya Minum Air Putih',
        body:
            'Penuhi kebutuhan cairan harianmu agar tubuh tetap segar dan terhindar dari kram.',
        hour: 10,
        minute: 0,
      );
    } else {
      await _notificationService.cancel(NotificationService.idWaterReminder);
    }

    // --- Existing: Period Hygiene / Pad Reminder (Daily at 13:30 PM) ---
    if (_padReminder) {
      await _notificationService.scheduleDailyWellnessReminder(
        id: NotificationService.idPadReminder,
        title: 'Pengingat Kebersihan Menstruasi',
        body:
            'Ganti pembalut secara berkala untuk menjaga kenyamanan dan higienitas.',
        hour: 13,
        minute: 30,
      );
    } else {
      await _notificationService.cancel(NotificationService.idPadReminder);
    }

    // --- Existing: Vitamin & Iron Supplement Reminder (Daily at 20:00 PM) ---
    if (_vitaminReminder) {
      await _notificationService.scheduleDailyWellnessReminder(
        id: NotificationService.idVitaminReminder,
        title: 'Waktunya Minum Suplemen / Vitamin',
        body:
            'Jangan lupa minum suplemen zat besi atau vitamin harianmu malam ini.',
        hour: 20,
        minute: 0,
      );
    } else {
      await _notificationService.cancel(NotificationService.idVitaminReminder);
    }
  }

  // ---------------------------------------------------------------------------
  // App Activity Tracking & Inactivity Reminder
  // ---------------------------------------------------------------------------

  /// Records the current timestamp as the last time the user opened the app.
  /// Should be called from HomeScreen initState and on app resume.
  Future<void> recordAppOpened() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastOpenKey, DateTime.now().millisecondsSinceEpoch);

      // Cancel any pending inactivity reminder since the user is now active
      await _notificationService.cancel(
        NotificationService.idInactivityReminder,
      );

      // Schedule the next inactivity reminder for 2 days from now at 10:00 AM
      await _scheduleInactivityReminder();

      debugPrint('Recorded app open and rescheduled inactivity reminder');
    } catch (e) {
      debugPrint('Error recording app open: $e');
    }
  }

  /// Schedules an inactivity notification 2 days from now at 10:00 AM.
  /// This gets cancelled and rescheduled every time the user opens the app.
  Future<void> _scheduleInactivityReminder() async {
    final now = DateTime.now();
    final inactivityDate = DateTime(now.year, now.month, now.day + 2, 10, 0);

    await _notificationService.scheduleInactivityReminder(
      scheduledDate: inactivityDate,
      title: 'Kami Merindukanmu',
      body:
          'Kamu sudah lebih dari 2 hari tidak membuka Kalmeda. Yuk, buka dan catat kondisimu agar pantauan siklus tetap akurat.',
      payload: 'open_home',
    );
  }

  /// Sends a test notification to verify delivery on the device immediately.
  Future<void> sendTestNotification() async {
    await _notificationService.requestPermissions();
    await _notificationService.showCycleNotification(
      id: 999,
      title: 'Kalmeda - Uji Notifikasi',
      body:
          'Notifikasi lokal Kalmeda berhasil terpasang dan siap mengirimkan pengingat.',
    );
  }
}
