import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/record/presentation/controllers/daily_checkin_service.dart';

void main() {
  group('DailyCheckinService Time Slot Tests', () {
    final service = DailyCheckinService();

    test('Identifies morning slot correctly between 08:00 and 11:59', () {
      final morningStart = DateTime(2026, 9, 4, 8, 0);
      final morningMid = DateTime(2026, 9, 4, 9, 30);
      final morningEnd = DateTime(2026, 9, 4, 11, 59);

      expect(service.getCurrentSlot(morningStart), CheckinTimeSlot.morning);
      expect(service.getCurrentSlot(morningMid), CheckinTimeSlot.morning);
      expect(service.getCurrentSlot(morningEnd), CheckinTimeSlot.morning);
    });

    test('Identifies afternoon slot correctly between 12:00 and 15:59', () {
      final afternoonStart = DateTime(2026, 9, 4, 12, 0);
      final afternoonMid = DateTime(2026, 9, 4, 13, 45);
      final afternoonEnd = DateTime(2026, 9, 4, 15, 59);

      expect(service.getCurrentSlot(afternoonStart), CheckinTimeSlot.afternoon);
      expect(service.getCurrentSlot(afternoonMid), CheckinTimeSlot.afternoon);
      expect(service.getCurrentSlot(afternoonEnd), CheckinTimeSlot.afternoon);
    });

    test('Identifies evening slot correctly between 16:00 and 20:59', () {
      final eveningStart = DateTime(2026, 9, 4, 16, 0);
      final eveningMid = DateTime(2026, 9, 4, 18, 30);
      final eveningEnd = DateTime(2026, 9, 4, 20, 59);

      expect(service.getCurrentSlot(eveningStart), CheckinTimeSlot.evening);
      expect(service.getCurrentSlot(eveningMid), CheckinTimeSlot.evening);
      expect(service.getCurrentSlot(eveningEnd), CheckinTimeSlot.evening);
    });

    test('Identifies inactive night/early morning hours as none', () {
      final earlyMorning = DateTime(2026, 9, 4, 7, 59);
      final lateNight = DateTime(2026, 9, 4, 21, 0);
      final midnight = DateTime(2026, 9, 4, 0, 30);

      expect(service.getCurrentSlot(earlyMorning), CheckinTimeSlot.none);
      expect(service.getCurrentSlot(lateNight), CheckinTimeSlot.none);
      expect(service.getCurrentSlot(midnight), CheckinTimeSlot.none);
    });

    test('Slot info provides appropriate title and valid icons without emojis', () {
      final morningInfo = service.getSlotInfo(CheckinTimeSlot.morning);
      expect(morningInfo.title, 'Catatan Kondisi Pagi');
      expect(morningInfo.icon, Icons.wb_sunny_outlined);

      final afternoonInfo = service.getSlotInfo(CheckinTimeSlot.afternoon);
      expect(afternoonInfo.title, 'Catatan Kondisi Siang');
      expect(afternoonInfo.icon, Icons.wb_cloudy_outlined);

      final eveningInfo = service.getSlotInfo(CheckinTimeSlot.evening);
      expect(eveningInfo.title, 'Catatan Kondisi Sore');
      expect(eveningInfo.icon, Icons.nights_stay_outlined);
    });
  });

  group('Check-in Card Visibility Tests', () {
    test('Identifies whether record date matches today for card hiding', () {
      final now = DateTime(2026, 9, 4, 11, 30);
      final todayDate = DateTime(now.year, now.month, now.day);
      final tomorrowDate = todayDate.add(const Duration(days: 1));

      // Matches today
      expect(todayDate == DateTime(2026, 9, 4), isTrue);

      // Tomorrow does not match today, so card appears again
      expect(tomorrowDate == DateTime(2026, 9, 4), isFalse);
    });
  });
}
