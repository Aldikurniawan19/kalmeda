import 'dart:convert';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class representing a confirmed or predicted menstrual period interval.
class ConfirmedPeriodEntry {
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final bool isConfirmedStart;
  final bool isConfirmedEnd;
  final bool isOngoing;

  const ConfirmedPeriodEntry({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.isConfirmedStart = true,
    this.isConfirmedEnd = false,
    this.isOngoing = false,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'durationDays': durationDays,
        'isConfirmedStart': isConfirmedStart,
        'isConfirmedEnd': isConfirmedEnd,
        'isOngoing': isOngoing,
      };

  factory ConfirmedPeriodEntry.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['startDate']);
    final end = DateTime.parse(json['endDate']);
    return ConfirmedPeriodEntry(
      startDate: start,
      endDate: end,
      durationDays: (json['durationDays'] as num?)?.toInt() ??
          (end.difference(start).inDays + 1),
      isConfirmedStart: json['isConfirmedStart'] as bool? ?? true,
      isConfirmedEnd: json['isConfirmedEnd'] as bool? ?? false,
      isOngoing: json['isOngoing'] as bool? ?? false,
    );
  }
}

/// Persistent service storing direct user period confirmations across sessions.
class ConfirmedPeriodStorage {
  static const String _keyPrefix = 'confirmed_periods_v1_';

  static Future<List<ConfirmedPeriodEntry>> loadPeriods(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final rawList = prefs.getStringList(key) ?? [];
      final List<ConfirmedPeriodEntry> entries = [];
      for (final item in rawList) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          entries.add(ConfirmedPeriodEntry.fromJson(decoded));
        } catch (_) {}
      }
      entries.sort((a, b) => b.startDate.compareTo(a.startDate));
      return entries;
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePeriods(
    String userId,
    List<ConfirmedPeriodEntry> entries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final list = entries.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(key, list);
    } catch (_) {}
  }

  /// Seeds initial period from user profile setup if storage is currently empty.
  static Future<void> seedInitialPeriod({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    int durationDays = 5,
  }) async {
    final list = await loadPeriods(userId);
    final cleanStart = DateFormatter.dateOnly(startDate);
    final isAlreadyPresent = list.any(
      (e) => e.startDate.difference(cleanStart).inDays.abs() <= 3,
    );
    if (!isAlreadyPresent) {
      final isEnded = endDate != null && !endDate.isBefore(cleanStart);
      final cleanEnd = isEnded
          ? DateFormatter.dateOnly(endDate)
          : cleanStart.add(Duration(days: durationDays - 1));
      final actualDuration =
          isEnded ? (cleanEnd.difference(cleanStart).inDays + 1) : durationDays;

      list.add(ConfirmedPeriodEntry(
        startDate: cleanStart,
        endDate: cleanEnd,
        durationDays: actualDuration,
        isConfirmedStart: true,
        isConfirmedEnd: isEnded,
        isOngoing: !isEnded &&
            DateTime.now().difference(cleanStart).inDays < actualDuration,
      ));
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      await savePeriods(userId, list);
    }
  }

  /// Records period start confirmed by the user via H-2 or H+ confirmation prompt.
  static Future<void> recordPeriodStart({
    required String userId,
    required DateTime startDate,
    int durationDays = 5,
  }) async {
    final list = await loadPeriods(userId);
    final cleanStart = DateFormatter.dateOnly(startDate);
    final cleanEnd = cleanStart.add(Duration(days: durationDays - 1));

    // Remove overlapping entry within 3 days
    list.removeWhere(
      (e) => e.startDate.difference(cleanStart).inDays.abs() <= 3,
    );

    list.add(ConfirmedPeriodEntry(
      startDate: cleanStart,
      endDate: cleanEnd,
      durationDays: durationDays,
      isConfirmedStart: true,
      isConfirmedEnd: false,
      isOngoing: true,
    ));

    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    await savePeriods(userId, list);
  }

  /// Records period completion confirmed by the user via active period card prompt.
  static Future<void> recordPeriodEnd({
    required String userId,
    required DateTime endDate,
    DateTime? startDate,
  }) async {
    final list = await loadPeriods(userId);
    final cleanEnd = DateFormatter.dateOnly(endDate);

    if (list.isNotEmpty) {
      final latest = list.first;
      final start = startDate != null
          ? DateFormatter.dateOnly(startDate)
          : latest.startDate;
      final duration = (cleanEnd.difference(start).inDays + 1).clamp(2, 14);

      list[0] = ConfirmedPeriodEntry(
        startDate: start,
        endDate: cleanEnd,
        durationDays: duration,
        isConfirmedStart: latest.isConfirmedStart,
        isConfirmedEnd: true,
        isOngoing: false,
      );
    } else if (startDate != null) {
      final start = DateFormatter.dateOnly(startDate);
      final duration = (cleanEnd.difference(start).inDays + 1).clamp(2, 14);
      list.add(ConfirmedPeriodEntry(
        startDate: start,
        endDate: cleanEnd,
        durationDays: duration,
        isConfirmedStart: true,
        isConfirmedEnd: true,
        isOngoing: false,
      ));
    }
    await savePeriods(userId, list);
  }
}
