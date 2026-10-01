import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_colors.dart';

/// Central service managing local push notifications and reminder schedules for Kalmeda.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  NotificationService._internal();

  /// ValueNotifier notifying listeners when a notification is tapped with a payload.
  static final ValueNotifier<String?> onNotificationPayload = ValueNotifier<String?>(null);

  /// Notification Channel IDs
  static const String _cycleChannelId = 'kalmeda_cycle_channel';
  static const String _cycleChannelName = 'Pengingat Siklus Menstruasi';
  static const String _cycleChannelDesc = 'Notifikasi perkiraan haid, ovulasi, dan masa subur';

  static const String _wellnessChannelId = 'kalmeda_wellness_channel';
  static const String _wellnessChannelName = 'Pengingat Kesehatan & Hidrasi';
  static const String _wellnessChannelDesc = 'Notifikasi minum air, ganti pembalut, dan suplemen';

  static const String _checkinChannelId = 'kalmeda_checkin_channel';
  static const String _checkinChannelName = 'Pengingat Catat Kondisi Harian';
  static const String _checkinChannelDesc = 'Notifikasi pengingat untuk mencatat kondisi tubuh dan suasana hati harian';

  /// Notification IDs — existing reminders
  static const int idPeriodReminder = 101;
  static const int idFertileReminder = 102;
  static const int idWaterReminder = 103;
  static const int idPadReminder = 104;
  static const int idVitaminReminder = 105;
  static const int idDailyCheckinReminder = 106;

  /// Notification IDs — new cycle-aware reminders
  static const int idPrePeriodReminder = 110;
  static const int idPeriodDailyMorning = 111;
  static const int idPeriodDailyAfternoon = 112;
  static const int idPeriodEndingSoon = 113;
  static const int idInactivityReminder = 114;

  /// Initializes local notifications with platform-specific settings and timezone data.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      try {
        tz_data.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
      } catch (e) {
        debugPrint('Timezone initialization error (non-fatal): $e');
      }

      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Check if app was launched directly by tapping a notification
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationPayload.value = payload;
        }
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      onNotificationPayload.value = response.payload;
    }
  }

  /// Requests official device notification permission on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) await initialize();

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        // Request POST_NOTIFICATIONS permission (Android 13+)
        final notifGranted = await androidImpl?.requestNotificationsPermission();

        // Request SCHEDULE_EXACT_ALARM permission (Android 14+ denies by default)
        await androidImpl?.requestExactAlarmsPermission();

        return notifGranted ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Determines the appropriate AndroidScheduleMode based on exact alarm availability.
  /// Falls back to inexactAllowWhileIdle when exact alarms are not permitted.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;

    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final canScheduleExact = await androidImpl?.canScheduleExactNotifications() ?? false;
      if (canScheduleExact) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }

      // Attempt to request the permission if not yet granted
      await androidImpl?.requestExactAlarmsPermission();
      final retryCheck = await androidImpl?.canScheduleExactNotifications() ?? false;
      if (retryCheck) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('Error checking exact alarm capability: $e');
    }

    // Fallback: inexactAllowWhileIdle still delivers, just not at exact time
    debugPrint('Exact alarm not permitted, falling back to inexactAllowWhileIdle');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Displays an instant cycle notification.
  Future<void> showCycleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        _cycleChannelId,
        _cycleChannelName,
        channelDescription: _cycleChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: AppColors.primary,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing cycle notification: $e');
    }
  }

  /// Displays an instant wellness notification.
  Future<void> showWellnessNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        _wellnessChannelId,
        _wellnessChannelName,
        channelDescription: _wellnessChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        color: Color(0xFF0288D1),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing wellness notification: $e');
    }
  }

  /// Schedules a cycle notification for a future target date.
  Future<void> scheduleCycleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        _cycleChannelId,
        _cycleChannelName,
        channelDescription: _cycleChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: AppColors.primary,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('Scheduled cycle reminder $id for $scheduledDate (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('Error scheduling cycle reminder: $e');
    }
  }

  /// Calculates the next instance of a specific time in local timezone.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules a daily repeating wellness notification at a specific time.
  Future<void> scheduleDailyWellnessReminder({
    required int id,
    required String title,
    required String body,
    int hour = 9,
    int minute = 0,
    Color? color,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final scheduleMode = await _resolveScheduleMode();

      final androidDetails = AndroidNotificationDetails(
        _wellnessChannelId,
        _wellnessChannelName,
        channelDescription: _wellnessChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        color: color ?? const Color(0xFF0288D1),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      try {
        final tzDateTime = _nextInstanceOfTime(hour, minute);
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } catch (tzErr) {
        debugPrint('zonedSchedule fallback to periodicallyShow: $tzErr');
        await _notificationsPlugin.periodicallyShow(
          id,
          title,
          body,
          RepeatInterval.daily,
          details,
          androidScheduleMode: scheduleMode,
          payload: payload,
        );
      }

      debugPrint('Scheduled daily wellness reminder $id for $hour:$minute (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('Error scheduling daily wellness reminder: $e');
    }
  }

  /// Schedules a repeating daily check-in reminder when the user has not recorded their condition.
  Future<void> scheduleDailyCheckinReminder({
    int hour = 19,
    int minute = 30,
    String title = 'Bagaimana Kondisimu Hari Ini?',
    String body = 'Kamu belum mencatat kondisi fisik dan suasana hatimu hari ini. Buka Kalmeda untuk mencatat sekarang.',
    String payload = 'open_record',
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        _checkinChannelId,
        _checkinChannelName,
        channelDescription: _checkinChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: AppColors.primary,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      try {
        final tzDateTime = _nextInstanceOfTime(hour, minute);
        await _notificationsPlugin.zonedSchedule(
          idDailyCheckinReminder,
          title,
          body,
          tzDateTime,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } catch (tzErr) {
        debugPrint('zonedSchedule fallback to periodicallyShow for check-in: $tzErr');
        await _notificationsPlugin.periodicallyShow(
          idDailyCheckinReminder,
          title,
          body,
          RepeatInterval.daily,
          details,
          androidScheduleMode: scheduleMode,
          payload: payload,
        );
      }
      debugPrint('Scheduled daily check-in reminder for $hour:$minute (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('Error scheduling daily check-in reminder: $e');
    }
  }

  /// Schedules a one-time check-in notification at a specific future DateTime.
  /// Used for period-specific daily reminders that depend on cycle state.
  Future<void> scheduleCheckinReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String payload = 'open_record',
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        _checkinChannelId,
        _checkinChannelName,
        channelDescription: _checkinChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: AppColors.primary,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('Scheduled checkin reminder $id for $scheduledDate (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('Error scheduling checkin reminder: $e');
    }
  }

  /// Schedules an inactivity notification at a future DateTime.
  /// Used to remind users who haven't opened the app in more than 2 days.
  Future<void> scheduleInactivityReminder({
    required DateTime scheduledDate,
    String title = 'Kami Merindukanmu',
    String body = 'Kamu sudah lebih dari 2 hari tidak membuka Kalmeda. Yuk, buka dan catat kondisimu agar pantauan siklus tetap akurat.',
    String payload = 'open_home',
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        _checkinChannelId,
        _checkinChannelName,
        channelDescription: _checkinChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: AppColors.primary,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        idInactivityReminder,
        title,
        body,
        tzDateTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('Scheduled inactivity reminder for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling inactivity reminder: $e');
    }
  }

  /// Cancels a specific notification by ID.
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  /// Cancels all active notifications.
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}
